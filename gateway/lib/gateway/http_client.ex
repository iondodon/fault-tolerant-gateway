defmodule Gateway.HttpClient do
    use HTTPoison.Base

    def process_request_body(body) do
        Jason.encode!(body)
    end

end
