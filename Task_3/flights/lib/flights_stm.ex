defmodule FlightsStm do
  @moduledoc """
  Documentation for FlightsStm.
  """
  use Application
  alias :mnesia, as: Mnesia

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

  defp load_flights() do
    file = Application.app_dir(:flights_stm, "priv/flights")
    :logger.info("Loading file from: #{file}")
    # IO.inspect(file)
    body = case File.read(file) do
      {:ok, body}      -> String.split(body, "\n") |>
                          Enum.map(fn(x) -> String.split(x, ",") end)
      {:error, reason} -> :logger.error("#{inspect reason}")
    end
    # IO.inspect(body)
    out = Enum.map(body, fn(x) ->
      elem = [Flights, UUID.uuid4()] ++ Enum.map(x, &convert_entry/1)
      IO.inspect elem
      Mnesia.dirty_write(List.to_tuple(elem))
    end)
    IO.inspect out
  end

  def start_phase(:create_schema, _, _) do
    # _ = Application.stop(Mnesia)
    node = node()
    case Mnesia.create_schema([node]) do
      :ok -> :ok
      {:error, {node, {:already_exists, node}}} -> :ok
    end
    {:ok, _} = Application.ensure_all_started(Mnesia)
    case Mnesia.create_table(
      Flights, [attributes: [:id, :airline_code,
                             :airline_id, :dep_code, :dep_id,
                             :arr_code, :arr_id, :codeshare,
                             :num_stops, :aircraft_code]]) do
      {_, :ok} -> load_flights()
      {:aborted, _} -> :ok
    end
    case Mnesia.create_table(
      FlightCalendar, [attributes: [:id, :date, :flight_id, :occupation]]) do
      {_, :ok} -> :ok
      {:aborted, _} -> :ok
    end
  end

  def start_phase(:search_flights, _, phase_args) do
    IO.inspect phase_args
    {from, to} = phase_args
    flights = search_flights(from, to)
    # keys = Mnesia.dirty_all_keys(Flights)
    # obj = Mnesia.dirty_read({Flights, "75aed37d-8086-4e18-bbb1-00fc05516b27"})
    IO.inspect flights
    :ok
  end

  def start_phase(phase, start_type, phase_args) do
    IO.puts "flights_stm:start_phase(#{inspect phase},#{inspect start_type},#{inspect phase_args})."
  end

  def search_flights(from_code, to_code) do
    # obj = Mnesia.dirty_match_object({Flights, :_, :_, :_, "BHX", :_, "OPO", :_, :_, :_, :_})
    Mnesia.dirty_select(
      Flights,
      [{
        {Flights, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6",
                  :"$7", :"$8", :"$9", :"$10"},
        [
          {:==, :"$4", from_code},
          {:==, :"$6", to_code}
        ],
        [:"$$"]
    }])
    # IO.inspect obj
  end

  defp lookup_flight_reservations(id, date) do
    Mnesia.select(
      FlightCalendar,
      [{
        {FlightCalendar, :"$1", :"$2", :"$3", :"$4"},
        [
          {:==, :"$3", id},
          {:==, :"$2", date}
        ],
        [:"$$"]
    }])
  end

  def reserve_flight(id, date) do
    Mnesia.transaction(fn ->
      # flights = search_flights(from_code, to_code)
      case Mnesia.dirty_read(Flights, id) do
        [{Flights, _, _, _, _, _, _, _, _, _, _}] ->
          [[res_id, _, _, num_res]] =
          case lookup_flight_reservations(id, date) do
            [] -> [[UUID.uuid4(), date, id, 0]]
            flight -> flight
          end
          case num_res do
            num when num < 120 ->
              res = [FlightCalendar, res_id, date, id, num_res + 1]
              Mnesia.write(List.to_tuple(res))
              {:ok, res}
            _ -> {:flight_fully_occupied, res_id}
          end
        _ -> {:noexists, id}
      end
    end)
  end

  def start(_, _) do
    # {:ok, _pid} = BscSup.start_link()
    IO.puts "Starting..."
    # Application.ensure_started(:flights_stm)
    # pid = spawn_link(fn() -> IO.puts "ready" end)
    {:ok, self()}
  end

  def airport_list() do
    airports = Enum.map(:mnesia.dirty_all_keys(Flights),
      fn k -> :mnesia.dirty_read(Flights, k) end)
    airports = Enum.flat_map(airports,
      fn [{_, _, _, _, a, _, b, _, _, _, _}] -> [a, b] end)
    MapSet.new(airports) |> MapSet.to_list()
  end

  def random_reading_load_test(procs \\ 100) do
    airports = airport_list()
    # for _ <- 1..procs, do: spawn_link(fn ->
      from = Enum.random(airports)
      to = Enum.random(airports)
      search_flights(from, to)
    # end)
  end

  def concurrent_reading_load_test(procs \\ 100) do
    # for _ <- 1..procs, do: spawn_link(fn ->
      from = "JFK"
      to = "LAX"
      search_flights(from, to)
      # IO.inspect search_flights(from, to)
    # end)
  end

  def random_writing_test() do
    keys = Mnesia.dirty_all_keys(Flights)
    # for _ <- 1..procs, do: spawn_link(fn ->
      flight = Enum.random(keys)
      {:ok, date} = {2018, :rand.uniform(9) + 2, :rand.uniform(30)}
                  |> Date.from_erl()
      date = Date.to_iso8601(date)
      reserve_flight(flight, date)
      # IO.inspect reserve_flight(flight, date)
    # end)
  end

  def concurrent_writing_test(id) do
    date = "2018-09-25"
    reserve_flight(id, date)
  end
end
