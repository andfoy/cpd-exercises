defmodule BullyTest do
  use ExUnit.Case
  doctest Bully

  test "greets the world" do
    assert Bully.hello() == :world
  end
end
