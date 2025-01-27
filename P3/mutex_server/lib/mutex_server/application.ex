defmodule MutexServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Task, fn -> MutexServer.start end}
      # Starts a worker by calling: MutexServer.Worker.start_link(arg)
      # {MutexServer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MutexServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
