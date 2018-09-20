defmodule FlightsStmTest do
  use ExUnit.Case
  doctest FlightsStm

  test "search a specific flight" do
    assert length(FlightsStm.search_flights("BOG", "MAD")) == 2
  end

  test "reserve a flight" do
    rand_flight = Enum.random(:mnesia.dirty_all_keys(Flights))
    {_, {:ok, [_, _, _, _, num]}} = FlightsStm.reserve_flight(
      rand_flight, "2018-05-02")
    assert num == 1
  end

  test "fully reserve a flight" do
    rand_flight = Enum.random(:mnesia.dirty_all_keys(Flights))
    for _ <- 1..120, do: FlightsStm.reserve_flight(
      rand_flight, "2018-05-02")
    {_, response} = FlightsStm.reserve_flight(
      rand_flight, "2018-05-02")
    assert match?({:flight_fully_occupied, _}, response)
  end

  test "reserve a flight that does not exist" do
    {_, response} = FlightsStm.reserve_flight("bla-bla-bla", "2018-05-02")
    assert match?({:noexists, _}, response)
  end
end
