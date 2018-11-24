defmodule FlightsServerTest do
  use ExUnit.Case
  doctest FlightsServer

  test "greets the world" do
    assert FlightsServer.hello() == :world
  end
end
