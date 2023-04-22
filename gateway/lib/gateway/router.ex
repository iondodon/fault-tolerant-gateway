defmodule Gateway.Router do
    use Plug.Router
    use Plug.ErrorHandler
    alias Service.CircuitBreaker
    alias Gateway.Cache.ECache

    plug(:match)
    plug(
        Plug.Parsers,
        parsers: [:json, :urlencoded, :multipart],
        pass: ["text/*"],
        json_decoder: Jason
    )
    plug(:dispatch)

    defp rest_path(full_path) do
        case full_path do
            "/orders-service" <> rest -> rest
            "/menus-service" <> rest -> rest
            "/reports-service" <> rest -> rest
        end
    end

    defp handle_requests(conn, service) do
        request = %{
            service: service,
            method: String.to_atom(String.downcase(conn.method, :default)),
            path: rest_path(conn.request_path),
            body: conn.body_params,
            headers: conn.req_headers
        }

        case CircuitBreaker.request(request) do
            {:ok, response} ->
                send_resp(conn, response.status_code, response.body)
            {:error, reason} ->
                IO.inspect(reason)
                IO.inspect("Redirecting to a new service instance")
                handle_requests(conn, service)
            {:err_no_serv_av, message} ->
                send_resp(conn, 503, message)
        end
    end

    post "/register" do
        address = conn.body_params["address"]
        service = conn.body_params["service"]
        ECache.command("LPUSH #{service} #{address}")
        send_resp(conn, 200, service <> " " <> address <> " registed")
    end

    match "/menus-service/*_rest", do: handle_requests(conn, "menus-service")
    match "/reports-service/*_rest", do: handle_requests(conn, "reports-service")
    match "/orders-service/*_rest", do: handle_requests(conn, "orders-service")

    match _, do: send_resp(conn, 404, "404. not found!")
    defp handle_errors(conn, err), do: send_resp(conn, 500, err.reason.message)
end
