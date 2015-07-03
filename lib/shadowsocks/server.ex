defmodule ShadowSocks.Server do
  require Logger
  use GenServer
  @supervisor ShadowSocks.Supervisor
  @worker ShadowSocks.Worker

  def start_link(port) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary,
      packet: :raw, active: false, reuseaddr: true, backlog: 128])

    # TODO: Make this supervised
    {:ok, listener} = Task.start_link(__MODULE__, :accept, [socket])

    Logger.info "ShadowSocks server started at :#{port}"
    {:ok, {socket, listener}}
  end

  def accept(socket) do
    {:ok, channel} = :gen_tcp.accept(socket)

    import Supervisor.Spec
    {:ok, client} = Supervisor.start_child(@supervisor,
      worker(@worker, [channel], id: {@worker, channel}, restart: :transient))

    :ok = :gen_tcp.controlling_process(channel, client)

    accept(socket)
  end
end
