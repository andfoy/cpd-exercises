defmodule PlantsWeatherTraffic.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [{:mdns, "~> 1.0"},
     {:chumak, "~> 1.3"},
     {:msgpack, "~> 0.7.0"}]
  end
end
