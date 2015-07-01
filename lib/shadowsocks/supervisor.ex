defmodule ShadowSocks.Supervisor do
  use Supervisor

  def start_link(port) do
    Supervisor.start_link(__MODULE__, [port])
  end

  def init([port]) do
    children = [
      worker(ShadowSocks.Server, [port])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
