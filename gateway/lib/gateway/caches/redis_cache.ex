defmodule Gateway.Cache.RCache do
    @redis_port Application.get_env(:gateway_port, :redis_port, 6379)
    @redis_host Application.get_env(:gateway_port, :redis_host, "redis")

    def start_link do
        Redix.start_link(host: @redis_host, port: @redis_port, name: :redix)
    end

    def command(cmd) do
        Redix.command!(:redix, cmd)
    end

   def child_spec(_args) do
        %{
            id: __MODULE__,
            type: :worker,
            start: {__MODULE__, :start_link, []}
        }
   end
end