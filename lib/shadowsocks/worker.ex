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
    {key, encoder_iv} = ShadowSocks.Coder.evp_bytes_to_key(password, @key_len, @iv_len)
    {:ok, decoder_iv} = :gen_tcp.recv(channel, @iv_len)
    # :gen_tcp.send(channel, encoder_iv)
    encoder = ShadowSocks.Coder.new(key, encoder_iv)
    decoder = ShadowSocks.Coder.new(key, decoder_iv)
    IO.inspect(decoder_iv)
    :ok = :inet.setopts(channel, active: true)
    {:ok, {channel, key, encoder, decoder, ""}}
  end

  def handle_info({_event, _pid, bytes}, {channel, key, encoder, decoder, buffer}) do
    bytes
    |> IO.inspect
    |> String.length
    |> IO.inspect

    {new_decoder, decoded} = ShadowSocks.Coder.decode(decoder, bytes)
    IO.inspect(decoded)
    {domain, port, payload} = parse(decoded)
    {:noreply, {channel, key, encoder, new_decoder, buffer}}
  end

  def handle_info({:tcp_closed, pid}, state) do
    IO.puts "Worker stop"
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

  def parse(<< 3, len, domain :: binary-size(len), port :: size(16), payload :: binary >>) do
    {domain, port, payload}
    |> IO.inspect
  end

  def parse(data) do
    data
  end

end
