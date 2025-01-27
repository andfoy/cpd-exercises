defmodule FlightsThread.MixProject do
  use Mix.Project

  def project do
    [
      app: :flights_thread,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FlightsThread, []},
      extra_applications: [:logger, :mnesia],
      start_phases: [{:create_schema, []},
                     {:search_flights, {"BOG", "MAD"}},
                     {:stop, [3]}]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :elixir_uuid, "~> 1.2" },
      { :benchee, "~> 0.13.2" },
      { :mutex, "~> 1.0.0" }
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
