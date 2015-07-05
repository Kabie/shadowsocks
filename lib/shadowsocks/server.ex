defmodule ShadowSocks.Server do
  require Logger
  use GenServer
  @supervisor ShadowSocks.Supervisor
  @worker ShadowSocks.Worker

  def start_link(port, key, iv) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, {port, key, iv}, name: __MODULE__)
  end

  def init({port, key, iv}) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary,
      packet: :raw, active: false, reuseaddr: true, keepalive: true, backlog: 128])

    # TODO: Make this supervised

    {:ok, listener} = Task.start_link(__MODULE__, :accept, [socket, key, iv])

    Logger.info "ShadowSocks server started at :#{port}"
    {:ok, {socket, listener}}
  end

  def accept(socket, key, iv) do
    {:ok, channel} = :gen_tcp.accept(socket)

    import Supervisor.Spec
    {:ok, client} = Supervisor.start_child(@supervisor,
      worker(@worker, [channel, key, iv], id: {@worker, channel}, restart: :temporary))

    :ok = :gen_tcp.controlling_process(channel, client)

    accept(socket, key, iv)
  end
end
