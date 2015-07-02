defmodule ShadowSocks.Worker do
  use GenServer

  @key_len 16
  @iv_len 16

  def start_link(channel) do
    IO.puts "Worker started"
    IO.inspect channel

    GenServer.start_link(__MODULE__, channel)
  end

  def init(channel) do
    password = "password"
    {key, encode_iv} = ShadowSocks.Coder.evp_bytes_to_key(password, @key_len, @iv_len)
    {:ok, decode_iv} = :gen_tcp.recv(channel, @iv_len)
    # :gen_tcp.send(channel, encoder_iv)
    :ok = :inet.setopts(channel, active: true)
    {:ok, {channel, key, encode_iv, decode_iv}}
  end

  def handle_info({:tcp, channel, bytes}, {channel, key, _encode_iv, decode_iv} = state) do
    bytes
    |> IO.inspect
    |> String.length
    |> IO.inspect

    decoded = ShadowSocks.Coder.decode(bytes, key, decode_iv)
    IO.inspect(decoded)
    parse(decoded)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, channel}, {channel, _key, _encode_iv, _decode_iv} = state) do
    IO.puts "Worker stop"
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

  def parse(<<3, len, domain::binary-size(len), port::size(16), payload::binary>>) do
    {:ok, pid} = :gen_tcp.connect(to_char_list(domain), port, [:binary,
      packet: :raw, active: true])
    :ok = :gen_tcp.send(pid, payload)

    {domain, port, payload}
    |> IO.inspect
  end

  def parse(data) do
    {:unknown, data}
    |> IO.inspect
  end

end
