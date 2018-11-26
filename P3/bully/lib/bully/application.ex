defmodule Bully.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # rank = String.to_integer(System.get_env("RANK"))
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Bully.Worker.start_link(arg)
      # {Bully.Worker, arg},
      {Task, fn -> Bully.start end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bully.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
