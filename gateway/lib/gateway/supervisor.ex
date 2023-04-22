defmodule Gateway.Supervisor do
  use Supervisor

  @gateway_port Application.get_env(:gateway, :gateway_port, 7171)

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: GatewaySupervisor)
  end

  def init(_) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Gateway.Router, options: [port: @gateway_port]},
      Gateway.Cache.RCache,
      Gateway.Cache.ECache
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
