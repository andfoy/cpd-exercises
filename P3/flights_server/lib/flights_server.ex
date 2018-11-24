defmodule FlightsServer do
  @moduledoc """
  Documentation for FlightsServer.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FlightsServer.hello()
      :world

  """
  def hello do
    :world
  end
end

defmodule FlightsServer.Database do
  use GenServer

  def start_link(file) do
    GenServer.start_link(__MODULE__, [file], name: :flight_db)
  end

  defp convert_entry("\\N") do
    :empty
  end

  defp convert_entry(x) do
    {:ok, re} = :re.compile("^[0-9]+$")
    case :re.run(x, re) do
      {:match, _} ->
        {num, ""} = Integer.parse(x)
        num
      :nomatch -> x
    end
  end

  defp load_flights(file) do
    :logger.info("Loading file from: #{file}")
    # IO.inspect(file)
    body = case File.read(file) do
      {:ok, body}      -> String.split(body, "\n") |>
                          Enum.map(fn(x) -> String.split(x, ",") end)
      {:error, reason} -> :logger.error("#{inspect reason}")
    end

    Enum.reduce(body, %{}, fn x, db ->
      flight = Enum.map(x, &convert_entry/1)
      [_, _, from_code, _, to_code, _, _, _, _] = flight
      flight_id = UUID.uuid4()
      flight = [flight_id | flight]
      {_, db} = Map.get_and_update(db, from_code, fn x ->
        out_flights =
          case x do
            :nil -> %{}
            out_flights -> out_flights
          end
        {_, out_flights} = Map.get_and_update(out_flights, to_code, fn z ->
          out = case z do
            :nil -> [flight]
            flight_list -> [flight | flight_list]
          end
          {z, out}
        end)
        # db = Map.put(db, from_code, out_flights)
        {x, out_flights}
      end)
    db
    end)

  end

  def init(file) do
    db = load_flights(file)
    {:ok, {db, %{}}}
  end

  def handle_call({:search_flights, from_code, to_code}, _, {db, res}) do
    resp = case Map.get(db, from_code) do
      :nil -> []
      value -> Map.get(value, to_code)
    end
    {:reply, resp, {db, res}}
  end

  def handle_call(:random_flight, _, {db, res}) do
    from_key = Enum.random(Map.keys(db))
    to_key = Map.get(db, from_key)
            |> Map.keys()
            |> Enum.random()
    flight = Map.get(db, from_key)
            |> Map.get(to_key)
            |> Enum.random()
    {:reply, flight, {db, res}}
  end

  def handle_call({:reserve_flight, flight_id, date}, _, {db, res}) do
    # reservation_id = UUID.uuid4()
    {_, res} = Map.get_and_update(res, flight_id, fn v ->
      dates = case v do
        :nil -> %{}
        dates -> dates
      end
      {_, dates} = Map.get_and_update(dates, date, fn r ->
        reservations = case r do
          :nil -> 0
          count -> count
        end
        {r, reservations}
      end)
      {v, dates}
    end)
    num_res = Map.get(res, flight_id)
            |> Map.get(date)
    {code, res, num_res} = case num_res do
      num when num < 120 ->
        {:ok, put_in(res, [flight_id, date], num_res + 1), num_res + 1}
      _ -> {:flight_fully_occupied, res, num_res}
    end
    {:reply, {code, num_res}, {db, res}}
  end
end
