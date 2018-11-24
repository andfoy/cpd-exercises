defmodule FlightsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {FlightsServer.Database, Application.app_dir(:flights_server, "priv/flights")}
      # Starts a worker by calling: FlightsServer.Worker.start_link(arg)
      # {FlightsServer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FlightsServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
