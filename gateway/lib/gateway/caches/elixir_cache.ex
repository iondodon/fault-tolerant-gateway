defmodule Gateway.Cache.ECache do
    use GenServer, restart: :permanent
    require Logger

    @recv_data_length 0

    @ip Application.get_env(:gateway, :elixir_cache_host, {172, 17, 0, 1})
    @port Application.get_env(:gateway, :elixir_cache_port, 6666)
    
    def start_link(_args) do
       GenServer.start_link(__MODULE__, :nil, name: Gateway.Cache.ECache)
    end

    def command(command) do
        cache_response = GenServer.call(__MODULE__, {:command, command})
        parse_response(cache_response)
    end


    # callbacks on server side

    def init(_args) do
        case :gen_tcp.connect(@ip, @port, [:binary, active: false]) do
            {:ok, socket} -> 
                Logger.info("Connected to elixir cache")
                {:ok, socket}
            {:error, _reason} -> 
                Logger.info("Not able to connect to elixir cache")
                :ignore
        end
    end

    def handle_call({:command, command}, _from, socket) do
        response = with :gen_tcp.send(socket, command <> "\n"), 
                    do: :gen_tcp.recv(socket, @recv_data_length)
        
        case response do
            {:error, reason} ->
                {:stop, Kernel.inspect(reason), Kernel.inspect(reason), socket}
            {:ok, data} ->
                {:reply, data, socket}
        end
    end


    defp parse_response(response) do
        response = String.trim(response, " \r\n")
        case response do
            "(float) " <> value -> elem(Float.parse(value), 0)
            "(integer) " <> value -> elem(Integer.parse(value), 0)
            "(boolean) " <> value -> value
            "(atom) " <> value -> String.to_atom(value)
            "(binary) " <> value -> value
            "(function) " <> value -> value
            "(list) " <> values ->
                values = String.split(values)
                Enum.reduce(values, [], fn value, list -> 
                    list ++ [value] 
                end)
            "(tuple) " <> tuple -> tuple
            "(idunno) " <> _rest -> "idunno"
        end
    end
end