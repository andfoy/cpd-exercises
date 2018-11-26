defmodule Bully do
  @moduledoc """
  Documentation for Bully.
  """

  # Algorithm assumption: All nodes know all ranks beforehand
  @node_ranks %{:"bcv001@157.253.196.67" => 0,
              :"bcv002@157.253.243.8" => 1,
              :"bcv003@157.253.243.9" => 2,
              :"bcv004@157.253.243.10" => 3,
              :"bcv005@157.253.243.11" => 4,
              :"bcv006@157.253.243.16" => 5}

  defp larger_nodes() do
    rank = Map.get(@node_ranks, Node.self)
    nodes = Enum.filter(@node_ranks, fn {_, v} -> v > rank end)
          |> Enum.into(%{})
          |> Map.keys()
    nodes
  end

  defp connect() do
    alive_nodes = Enum.filter(@node_ranks, fn {node, _} -> Node.ping(node) == :pong end)
    if length(alive_nodes) == 0 do
      connect()
    end
end

  def start() do
    Process.register(self(), :bully)
    rank = Map.get(@node_ranks, Node.self())
    :logger.info("Node #{Node.self()} is starting with rank #{rank}")
    connect()
    # Announce rank to all available nodes larger than mine
    :logger.info("Announcing elections")
    nodes = larger_nodes()
    Enum.map(
      nodes, fn n -> send({:bully, n}, {:election, Node.self()}) end)
    loop(Node.self(), :confirm_election)
  end

  defp broadcast_message(nodes, message) do
    Enum.map(nodes, fn n -> send({:bully, n}, message) end)
  end

  defp loop(coordinator, :confirm_election) do
    # rank = Map.get(@node_ranks, Node.self())
    :logger.info("Wait for confirmation")
    receive do
      {:election_ok, _} ->
        :logger.info("Elections will take place")
        loop(coordinator, :await_victory)
      {:victory, node} ->
        Node.monitor(node, :true)
        :logger.info("#{node} is the new coordinator")
        loop(node, :ok)
      {:election, node} ->
        :logger.info("We're already on elections")
        send({:bully, node}, {:election_ok, Node.self()})
        loop(coordinator, :confirm_election)
      after
        1_000 ->
          :logger.info("I shall be coordinator")
          broadcast_message(Node.list, {:victory, Node.self()})
    end
  end

  defp loop(coordinator, :await_victory) do
    rank = Map.get(@node_ranks, Node.self())
    max_alive_rank = Enum.reduce(Node.list,
                      fn x, acc -> max(Map.get(@node_ranks, x), acc) end)
    if rank == max_alive_rank do
      :logger.info("I shall be coordinator")
      broadcast_message(Node.list, {:victory, Node.self()})
      loop(Node.self, :ok)
    else
      receive do
        {:victory, node} ->
          :logger.info("#{node} is the new coordinator")
          Node.monitor(node, :true)
          loop(node, :ok)
        {:election, node} ->
          :logger.info("We're already on elections")
          send({:bully, node}, {:election_ok, Node.self()})
          loop(coordinator, :await_victory)
      end
    end
  end

  defp loop(coordinator, :ok) do
    receive do
      {:nodedown, ^coordinator} ->
        :logger.info("Coordinator #{coordinator} is down, calling for new elections")
        broadcast_message(larger_nodes(), {:election, Node.self()})
        loop(coordinator, :confirm_election)
      {:election, node} ->
        :logger.info("Node #{node} has called for new elections")
        send({:bully, node}, {:election_ok, Node.self()})
        loop(coordinator, :await_victory)
      {:victory, node} ->
        :logger.info("#{node} is the new coordinator")
        Node.monitor(node, :true)
        loop(node, :ok)
    end
  end


end
