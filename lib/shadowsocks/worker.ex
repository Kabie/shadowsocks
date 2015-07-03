defmodule ShadowSocks.Worker do
  use GenServer

  @key_len 16
  @iv_len 16

  def start_link(client) do
    IO.puts "Worker #{inspect client} started"

    GenServer.start_link(__MODULE__, client)
  end

  @doc """
  Set coder, start receiving from client
  """
  def init(client) do
    password = "password"
    {key, encode_iv} = ShadowSocks.Coder.evp_bytes_to_key(password, @key_len, @iv_len)
    {:ok, decode_iv} = :gen_tcp.recv(client, @iv_len)
    # IO.inspect decode_iv
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

    remote = decoded
    |> parse_header
    |> connect_remote

    IO.puts "Link started #{inspect remote}"

    {:noreply, {:stream, client, remote, encoder, new_decoder}}
  end

  @doc """
  Handle streaming requests
  """
  def handle_info({:tcp, client, bytes}, {:stream, client, remote, encoder, decoder}) do
    {new_decoder, decoded} = bytes
    |> ShadowSocks.Coder.decode(decoder)

    :ok = :gen_tcp.send(remote, decoded)
    {:noreply, {:stream, client, remote, encoder, decoder}}
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
  def handle_info({:tcp_closed, client}, {_status, client, _remote, _encoder, _decoder} = state) do
    IO.puts "Worker #{inspect client} stop"
    {:stop, :normal, state}
  end
  def handle_info({:tcp_closed, remote}, {_status, _client, _remote, _encoder, _decoder} = state) do
    IO.puts "Link #{inspect remote} stop"
    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

  # Parse_header domain request
  defp parse_header(<<3, len, domain::binary-size(len), port::size(16), payload::binary>>) do
    {domain, port, payload}
  end

  defp parse_header(data) do
    IO.inspect data
    {:error, :unknown_request_type}
  end

  # Start connection to remote
  defp connect_remote({host, port, payload}) do
    {:ok, pid} = :gen_tcp.connect(to_char_list(host), port, [:binary,
      packet: :raw, active: true])
    :ok = :gen_tcp.send(pid, payload)
    pid
  end

end
