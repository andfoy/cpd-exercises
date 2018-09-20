defmodule FlightsThreadTest do
  use ExUnit.Case
  doctest FlightsThread

  test "search a specific flight" do
    assert length(FlightsThread.search_flights("BOG", "MAD")) == 2
  end

  test "reserve a flight" do
    [id, _, _, _, _, _, _, _, _, _] = FlightsThread.random_flight()
    {:ok, num} = FlightsThread.reserve_flight(id, "2018-05-02")
    assert num == 1
  end

  test "fully reserve a flight" do
    [id, _, _, _, _, _, _, _, _, _] = FlightsThread.random_flight()
    for _ <- 1..120, do: FlightsThread.reserve_flight(
      id, "2018-05-02")
    response = FlightsThread.reserve_flight(
      id, "2018-05-02")
    assert match?({:flight_fully_occupied, _}, response)
  end
end
