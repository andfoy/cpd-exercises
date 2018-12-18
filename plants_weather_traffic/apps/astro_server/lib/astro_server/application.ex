defmodule AstroServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    hostname = AstroServer.get_address()
             |> Tuple.to_list
             |> Enum.join(".")
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: AstroServer.Worker.start_link(arg)
      # {AstroServer.Worker, arg},
      {AstroServer, []},
      {AstroZMQ, [hostname, 8600]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AstroServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
