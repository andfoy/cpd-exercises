defmodule Dinner do
  use GenServer


  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, {}}
  end

  def handle_cast(:start, state) do
    chop1 = Chopstick.start()
    chop2 = Chopstick.start()
    chop3 = Chopstick.start()
    chop4 = Chopstick.start()
    chop5 = Chopstick.start()
    philo3 = Philo.start("Kant", chop2, chop3)
    philo1 = Philo.start("Marx", chop5, chop1)
    philo2 = Philo.start("Hegel", chop1, chop2)
    philo4 = Philo.start("Heidegger", chop4, chop5)
    philo5 = Philo.start("Descartes", chop5, chop1)
    {:noreply, state}
  end
end

defmodule DiningPhilo do
  def start() do
    children = [
      {Dinner, []}
    ]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    # pid
    GenServer.cast(Dinner, :start)
    pid
  end
end
