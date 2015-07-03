defmodule ShadowSocks do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    opts = Application.get_env(__MODULE__, :server)
    port = Dict.get(opts, :port)
    password = Dict.get(opts, :password)
    key_length = Dict.get(opts, :key_length)
    iv_length = Dict.get(opts, :iv_length)
    {key, iv} = ShadowSocks.Coder.evp_bytes_to_key(password, key_length, iv_length)

    children = [
      # Define workers and child supervisors to be supervised
      worker(ShadowSocks.Supervisor, [port, key, iv])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShadowSocks.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
