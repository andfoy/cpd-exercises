defmodule MutexServer do
  @coordinator :"bcv005@157.253.243.11"

  def start do
    Process.register(self(), :mutex)
    case Node.self() == @coordinator do
      :true -> coordinate(:nil, :queue.new)
      :false ->
        wait_for_coordinator()
        process(:false)
    end
  end

  defp wait_for_coordinator() do
    :logger.info("Waiting for coordinator to connect")
    case Node.ping(@coordinator) do
      :pang -> wait_for_coordinator()
      :pong -> :ok
    end
  end

  defp process(has_lock) when has_lock do
    case :rand.uniform(16) > 8 do
      :true ->
        :logger.info("Releasing lock")
        send({:mutex, @coordinator}, {:release, Node.self()})
        receive do
          {:ok, :release} -> process(:false)
        end
      :false -> process(has_lock)
    end
  end

  defp process(has_lock) when not has_lock do
    case :rand.uniform(16) > 8 do
      :true ->
        :logger.info("Adquiring lock")
        send({:mutex, @coordinator}, {:adquire, Node.self()})
        receive do
          {:ok, :lease} -> process(:true)
        end
      :false -> process(has_lock)
    end
  end

  defp coordinate(current_owner, queue) do
    :logger.info("Coordinator #{@coordinator} is waiting for messages")
    receive do
      {:adquire, node} ->
        :logger.info("Node #{node} wants to adquire lock")
        Node.monitor(node, :true)
        if match?(^current_owner, node) do
          :logger.info("Node #{node} has already adquired the lock")
          coordinate(current_owner, queue)
        else
          case current_owner do
            :nil ->
              :logger.info("Node #{node} is adquiring the lock")
              send({:mutex, node}, {:ok, :lease})
              coordinate(node, queue)
            _ ->
              :logger.info("Node #{node} must wait")
              queue = :queue.in(node, queue)
              coordinate(node, queue)
          end
        end
      {:release, node} ->
        :logger.info("Node #{node} is releasing the lock")
        send({:mutex, node}, {:ok, :release})
        Node.monitor(node, :false)
        case :queue.out(queue) do
          {{:value, qnode}, queue} ->
            Node.monitor(qnode, :true)
            :logger.info("Node #{qnode} is adquiring the lock")
            send({:mutex, qnode}, {:ok, :lease})
            coordinate(node, queue)
          {:empty, queue} ->
            :logger.info("Queue is empty")
            coordinate(:nil, queue)
        end
      {:nodedown, node} ->
        :logger.info("Node #{node} is down!")
        case :queue.out(queue) do
          {{:value, qnode}, queue} ->
            Node.monitor(qnode, :true)
            :logger.info("Node #{qnode} is adquiring the lock")
            send({:mutex, qnode}, {:ok, :lease})
            coordinate(node, queue)
          {:empty, queue} ->
            :logger.info("Queue is empty")
            coordinate(:nil, queue)
        end
    end
  end
end
