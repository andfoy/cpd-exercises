defmodule Philo do
  def start(name, left_chopstick, right_chopstick) do
    ref = make_ref()
    IO.inspect "#{name} has ID #{inspect ref}"
    spawn_link(__MODULE__, :loop, [name, left_chopstick, right_chopstick, ref, :think])
  end

  def pick_left(chopstick, ref, :think) do
    send chopstick, {:pick, self(), ref}
    receive do
      {:ok, ^ref} -> :wait_right
      {:busy, ^ref} -> :think
    end
  end

  def pick_left(chopstick, ref, :wait_left) do
    send chopstick, {:pick, self(), ref}
    receive do
      {:ok, ^ref} -> :eat
      {:busy, ^ref} -> :wait_left
    end
  end

  def pick_right(chopstick, ref, :think) do
    send chopstick, {:pick, self(), ref}
    receive do
      {:ok, ^ref} -> :wait_left
      {:busy, ^ref} -> :think
    end
  end

  def pick_right(chopstick, ref, :wait_right) do
    send chopstick, {:pick, self(), ref}
    receive do
      {:ok, ^ref} -> :eat
      {:busy, ^ref} -> :wait_right
    end
  end

  def drop_left(chopstick, ref, :wait_right) do
    send chopstick, {:drop, self(), ref}
    receive do
      {:ok, ^ref} -> :think
    end
  end

  def drop_left(chopstick, ref, :eat) do
    send chopstick, {:drop, self(), ref}
    receive do
      {:ok, ^ref} -> :wait_left
    end
  end

  def drop_right(chopstick, ref, :wait_left) do
    send chopstick, {:drop, self(), ref}
    receive do
      {:ok, ^ref} -> :think
    end
  end

  def drop_right(chopstick, ref, :eat) do
    send chopstick, {:drop, self(), ref}
    receive do
      {:ok, ^ref} -> :wait_right
    end
  end

  def wait_left(left, right, ref) do
    drop_right_chop = :rand.uniform(2) == 1
    case drop_right_chop do
      :true -> drop_right(right, ref, :wait_left)
      _ -> pick_left(left, ref, :wait_left)
    end
  end

  def wait_right(left, right, ref) do
    drop_left_chop = :rand.uniform(2) == 1
    case drop_left_chop do
      :true -> drop_left(left, ref, :wait_right)
      _ -> pick_right(right, ref, :wait_right)
    end
  end

  def eat(left, right, ref) do
    stop_eating = :rand.uniform(2) == 1
    drop_left = :rand.uniform(2) == 1
    case stop_eating do
      :true -> case drop_left do
        :true -> drop_left(left, ref, :eat)
        _ -> drop_right(right, ref, :eat)
      end
      _ -> :eat
    end
  end

  def think(left, right, ref) do
    pick_chop = :rand.uniform(2) == 2
    left_pick = :rand.uniform(2) == 1
    # IO.puts "Is philosopher #{name} going to pick_chop? #{pick_chop}"
    case pick_chop do
      :true -> case left_pick do
        :true ->
          # IO.puts "#{name} will pick left chop"
          pick_left(left, ref, :think)
        _ ->
          # IO.puts "#{name} will pick right chop"
          pick_right(right, ref, :think)
      end
      _ -> :think
    end
  end


  def loop(name, left, right, ref, status) do
    status = case status do
      :think -> think(left, right, ref)
      :eat ->
        IO.inspect "#{name} is now eating"
        eat(left, right, ref)
      :wait_left -> wait_left(left, right, ref)
      :wait_right -> wait_right(left, right, ref)
    end
    loop(name, left, right, ref, status)
  end

end
