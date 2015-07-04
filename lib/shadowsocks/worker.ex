defmodule ShadowSocks.Worker do
  require Logger
  use GenServer

  def start_link(client, key, iv) do
    Logger.info "Worker #{inspect client} started"

    GenServer.start_link(__MODULE__, {client, key, iv})
  end

  @doc """
  Set coder, start receiving from client
  """
  def init({client, key, encode_iv}) do
    {:ok, decode_iv} = :gen_tcp.recv(client, :erlang.size(encode_iv))
    :gen_tcp.send(client, encode_iv)
    :ok = :inet.setopts(client, active: true)
    {:ok, {:init, client, nil, {key, encode_iv, ""}, {key, decode_iv, ""}}}
  end

  @doc """
  Handle first requests
  """
  def handle_info({:tcp, client, bytes}, {:init, client, nil, encoder, decoder}) do
    {new_decoder, decoded} = bytes
    |> ShadowSocks.Coder.decode(decoder)

    case decoded
    |> parse_header
    |> connect_remote do
      {{:ok, remote}, payload} ->
        :ok = :gen_tcp.send(remote, payload)
        Logger.info "Link started #{inspect remote}"
        {:noreply, {:stream, client, remote, encoder, new_decoder}}
      {{:error, reason}, _} ->
        Logger.warn "Link quit for: #{inspect reason}"
        {:stop, reason, {:stop, client, nil, encoder, decoder}}
    end
  end

  @doc """
  Handle streaming requests
  """
  def handle_info({:tcp, client, bytes}, {:stream, client, remote, encoder, decoder}) do
    {new_decoder, decoded} = bytes
    |> ShadowSocks.Coder.decode(decoder)

    :gen_tcp.send(remote, decoded)
    {:noreply, {:stream, client, remote, encoder, new_decoder}}
  end

  @doc """
  Received remote response
  """
  def handle_info({:tcp, remote, bytes}, {:stream, client, remote, encoder, decoder}) do
    {new_encoder, encoded} = bytes
    |> ShadowSocks.Coder.encode(encoder)

    :ok = :gen_tcp.send(client, encoded)
    {:noreply, {:stream, client, remote, new_encoder, decoder}}
  end

  @doc """
  Client disconnect
  """
  def handle_info({:tcp_closed, client}, {_status, client, remote, encoder, decoder}) do
    Logger.info "Worker #{inspect client} stop"
    {:stop, :normal, {:stop, client, remote, encoder, decoder}}
  end

  def handle_info({:tcp_error, client, reason}, {_status, client, remote, encoder, decoder}) do
    Logger.info "Worker #{inspect client} stop for: #{inspect reason}"
    {:stop, :normal, {:stop, client, remote, encoder, decoder}}
  end

  @doc """
  Remote disconnect
  """
  def handle_info({:tcp_closed, remote}, {_status, _client, remote, _encoder, _decoder} = state) do
    Logger.info "Link #{inspect remote} stop"
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn "Got unknown msg"
    {:noreply, state}
  end

  # Domain header
  defp parse_header(<<3, len, domain::binary-size(len), port::size(16), payload::binary>>) do
    IO.inspect domain
    {to_char_list(domain), port, payload}
  end

  # IPv4 header
  defp parse_header(<<1, i1, i2, i3, i4, port::size(16), payload::binary>>) do
    IO.inspect {i1, i2, i3, i4}
    {{i1, i2, i3, i4}, port, payload}
  end

  defp parse_header(header) do
    Logger.error "Can't parse header: #{inspect header}"
    {:error, :unknown_header_type}
  end

  # Start connection to remote
  defp connect_remote({address, port, payload}) do
    {:gen_tcp.connect(address, port, [:binary, packet: :raw, active: true]), payload}
  end

end
