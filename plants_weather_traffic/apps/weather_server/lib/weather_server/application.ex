defmodule WeatherServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    hostname = WeatherServer.get_address()
             |> Tuple.to_list
             |> Enum.join(".")
    children = [
      # Starts a worker by calling: WeatherServer.Worker.start_link(arg)
      # {WeatherServer.Worker, arg},
      {Weather.AstroClient, :ok},
      {WeatherServer, []},
      {WeatherZMQ, [hostname, 8700]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeatherServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
