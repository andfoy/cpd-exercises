defmodule FlightsCSP do
  @moduledoc """
  Documentation for FlightsStm.
  """
  import Supervisor.Spec
  use Application
  use CSP

  def start_phase(:create_schema, _, _) do
    # _ = Application.stop(Mnesia)
    file = Application.app_dir(:flights_csp, "priv/flights")
    {:ok, pid} = FlightsDatabase.start_link(file)
    # :erlang.register(arg1, arg2)
    Process.register(pid, :flight_server)
    :ok
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
    server = Process.whereis(:flight_server)
    GenServer.call(server, {:search_flights, from_code, to_code}, :infinity)
  end

  def reserve_flight(id, date) do
    server = Process.whereis(:flight_server)
    GenServer.call(server, {:reserve_flight, id, date}, :infinity)
  end

  def random_flight() do
    server = Process.whereis(:flight_server)
    GenServer.call(server, :random_flight, :infinity)
  end

  def start(_, _) do
    IO.puts "Starting..."
    {:ok, self()}
  end

  def random_read_test(nprocs) do
    Benchee.run(%{"random read test" => fn -> random_flight() end},
                memory_time: 2, parallel: nprocs)
  end

  def concurrent_read_test(nprocs) do
    Benchee.run(%{"random read test" => fn -> search_flights("BOG", "JFK") end},
                memory_time: 2, parallel: nprocs)
  end

  defp random_write() do
    # resource_id = {User, {:id, 1}}
    # lock = Mutex.await(@mut, resource_id)
    [id, _, _, _, _, _, _, _, _, _] = random_flight()
    {:ok, date} = {2018, :rand.uniform(9) + 2, :rand.uniform(30)}
                  |> Date.from_erl()
    date = Date.to_iso8601(date)
    reserve_flight(id, date)
  end

  def random_write_test(nprocs) do
    children = [
      worker(Channel, [[name: MyApp.Channel, buffer_size: 1]])
    ]
    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    # channel = Channel.new
    Benchee.run(%{"random write test" => fn ->
      Channel.put(MyApp.Channel, :write)
      random_write()
      Channel.get(MyApp.Channel)
    end}, memory_time: 2, parallel: nprocs)
  end

  defp concurrent_write(id, date) do
    reserve_flight(id, date)
    # IO.inspect value
  end

  def concurrent_write_test(nprocs) do
    [id, _, _, _, _, _, _, _, _, _] = random_flight()
    {:ok, date} = {2018, :rand.uniform(9) + 2, :rand.uniform(30)}
                  |> Date.from_erl()
    date = Date.to_iso8601(date)
    channel = Channel.new
    Benchee.run(%{"concurrent write test" => fn ->
      Channel.put(channel, :write)
      concurrent_write(id, date)
      Channel.get(channel)
    end}, memory_time: 2, parallel: nprocs)
  end

end
