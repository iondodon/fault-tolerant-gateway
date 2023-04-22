FROM elixir:1.14.4

COPY ./ /gateway
WORKDIR /gateway

RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get

CMD iex -S mix

EXPOSE 7171