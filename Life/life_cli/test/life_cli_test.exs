defmodule LifeCLITest do
  use ExUnit.Case
  doctest LifeCLI

  test "greets the world" do
    assert LifeCLI.hello() == :world
  end
end
