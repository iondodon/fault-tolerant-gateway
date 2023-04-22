defmodule Gateway do
  use Application

  def start(_type, _args) do
    Gateway.Supervisor.start_link()
  end
end
