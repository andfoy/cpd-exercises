defmodule TrafficServerTest do
  use ExUnit.Case
  doctest TrafficServer

  test "greets the world" do
    assert TrafficServer.hello() == :world
  end
end
