defmodule AstroServerTest do
  use ExUnit.Case
  doctest AstroServer

  test "greets the world" do
    assert AstroServer.hello() == :world
  end
end
