defmodule MutexServer do
  @coordinator :"bcv005@157.253.243.11"

  def start do
    Process.register(self(), :mutex)
    case Node.self() == @coordinator do
      :true -> coordinate(:nil, :queue.new)
      :false ->
        wait_for_coordinator()
        process()
    end
  end

  defp wait_for_coordinator() do
    case Node.ping(@coordinator) do
      :pang -> wait_for_coordinator()
      :pong -> :ok
    end
  end

  defp process() do
    case :rand.uniform(16) > 8 do
      :true -> send({:mutex, @coordinator}, {:adquire, Node.self()})
    end
    receive do
      {:ok, :lease} -> process()
    end
  end

  defp coordinate(current_owner, queue) do
    receive do
      {:adquire, node} ->
        Node.monitor(node, :true)
        if match?(^current_owner, node) do
          coordinate(current_owner, queue)
        else
          case current_owner do
            :nil ->
              send({:mutex, node}, {:ok, :lease})
              coordinate(node, queue)
            _ ->
              queue = :queue.in(node, queue)
              coordinate(node, queue)
          end
        end
      {:release, node} ->
        Node.monitor(node, :false)
        case :queue.out(queue) do
          {{:value, qnode}, queue} ->
            send({:mutex, qnode}, {:ok, :lease})
            coordinate(node, queue)
          {:empty, queue} ->
            coordinate(:nil, queue)
        end
      {:nodedown, node} ->
        case :queue.out(queue) do
          {{:value, qnode}, queue} ->
            send({:mutex, qnode}, {:ok, :lease})
            coordinate(node, queue)
          {:empty, queue} ->
            coordinate(:nil, queue)
        end
    end
  end
end
