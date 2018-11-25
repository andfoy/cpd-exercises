defmodule MutexServerTest do
  use ExUnit.Case
  doctest MutexServer

  test "greets the world" do
    assert MutexServer.hello() == :world
  end
end
