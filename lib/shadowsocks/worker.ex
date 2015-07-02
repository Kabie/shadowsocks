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
    IO.inspect decode_iv
    # :gen_tcp.send(client, encode_iv)
    :ok = :inet.setopts(client, active: true)
    {:ok, {client, key, encode_iv, decode_iv}}
  end

  @doc """
  Handler for client requests
  """
  def handle_info({:tcp, client, bytes}, {client, key, _encode_iv, decode_iv} = state) do
    bytes
    |> IO.inspect
    |> ShadowSocks.Coder.decode(key, decode_iv)
    |> IO.inspect
    |> parse
    |> IO.inspect
    |> forward_request

    {:noreply, state}
  end

  @doc """
  Received target response
  """
  def handle_info({:tcp, remote, bytes}, {client, key, encode_iv, _decode_iv} = state) do
    bytes
    |> IO.inspect
    |> ShadowSocks.Coder.encode(key, encode_iv)
    |> IO.inspect
    |> send_back_to(client)

    {:noreply, state}
  end

  @doc """
  Client disconnect
  """
  def handle_info({:tcp_closed, client}, {client, _key, _encode_iv, _decode_iv} = state) do
    IO.puts "Worker #{inspect client} stop"
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

  # Parse domain request
  defp parse(<<3, len, domain::binary-size(len), port::size(16), payload::binary>>) do
    {domain, port, payload}
  end

  defp parse(data) do
    {:error, :unknown_request_type}
  end

  defp forward_request({:error, reason}) do
    IO.puts "Error: #{reason}"
  end

  # Send request to remote
  defp forward_request({host, port, payload}) do
    {:ok, pid} = :gen_tcp.connect(to_char_list(host), port, [:binary,
      packet: :raw, active: true])
    :ok = :gen_tcp.send(pid, payload)
    IO.puts "Link started #{inspect pid}"
  end

  defp send_back_to(bytes, client) do
    :ok = :gen_tcp.send(client, bytes)
  end

end
