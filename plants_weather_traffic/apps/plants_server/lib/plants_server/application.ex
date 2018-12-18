defmodule PlantsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    # :logger.info("#{inspect Mdns.Client.query("_ssh._tcp.local")}")

    children = [
      # Starts a worker by calling: PlantsServer.Worker.start_link(arg)
      # {PlantsServer.Worker, arg},
      # %{
      #   id: Mdns.Server,
      #   start: {Mdns.Server, :start_link, []}
      # },
      {Plants.WeatherClient, :ok},
      {PlantsServer.DNS, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlantsServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
