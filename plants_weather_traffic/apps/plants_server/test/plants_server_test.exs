defmodule PlantsServerTest do
  use ExUnit.Case
  doctest PlantsServer

  test "greets the world" do
    assert PlantsServer.hello() == :world
  end
end
