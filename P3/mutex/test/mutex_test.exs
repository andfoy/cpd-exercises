defmodule MutexTest do
  use ExUnit.Case
  doctest Mutex

  test "greets the world" do
    assert Mutex.hello() == :world
  end
end
