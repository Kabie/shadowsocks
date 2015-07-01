defmodule ShadowSocks.Worker do
  use GenServer

  def start_link(channel) do
    IO.puts "Worker started"

    GenServer.start_link(__MODULE__, channel)
  end

  def init(channel) do
    :ok = :inet.setopts(channel, active: true)
    {:ok, channel}
  end

  def handle_info(msg, channel) do
    IO.inspect msg
    {:noreply, channel}
  end

end
