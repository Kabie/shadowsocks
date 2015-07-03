defmodule ShadowSocks.Supervisor do
  use Supervisor

  def start_link(port, key, iv) do
    Supervisor.start_link(__MODULE__, {port, key, iv})
  end

  def init({port, key, iv}) do
    children = [
      worker(ShadowSocks.Server, [port, key, iv])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
