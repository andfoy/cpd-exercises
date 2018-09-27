defmodule Chopstick do
  def start() do
    spawn_link(__MODULE__, :loop, [:free, :nil])
  end

  def loop(:busy, ref) do
    {state, ref} = receive do
      {:pick, caller, nref} ->
        send caller, {:busy, nref}
        {:busy, ref}
      {:drop, caller, ^ref} ->
        # ^ref = nref
        send caller, {:ok, ref}
        {:free, :nil}
      {:drop, caller, nref} ->
        send caller, {:busy, nref}
        {:busy, ref}
    end
    loop(state, ref)
  end

  def loop(:free, _) do
    {state, ref} = receive do
      {:pick, caller, ref} ->
        # IO.puts "Chop belongs to #{inspect ref}"
        send caller, {:ok, ref}
        {:busy, ref}
    end
    loop(state, ref)
  end
end
