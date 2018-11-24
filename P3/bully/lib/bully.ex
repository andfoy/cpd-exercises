defmodule Bully do
  @moduledoc """
  Documentation for Bully.
  """

  @node_list [:"bcv001@157.253.196.67",
              :"bcv002@157.253.243.8",
              :"bcv003@157.253.243.9",
              :"bcv004@157.253.243.10",
              :"bcv005@157.253.243.11",
              :"bcv006@157.253.243.16"]

  defp connect() do
    # sup_node = Enum.at(@node_list, rem(rank - 1, length(@node_list)))
    alive_nodes = Enum.filter(@node_list, fn node -> Node.ping(node) == :pong end)
    if length(alive_nodes) == 0 do
      connect()
    end
  end

  def start(rank) do
    Process.register(self(), :bully)
    connect()
    # Announce rank to all available nodes
    Enum.map(
      Node.list, fn n -> send({:bully, n}, {:rank, Node.self(), rank}) end)
    loop(Node.self(), %{Node.self() => rank})
  end

  defp loop(coordinator, rank_map) do
    rank = Map.get(rank_map, Node.self())
    max_rank = Map.get(rank_map, coordinator)
    receive do
      {:rank, node_name, node_rank} ->
        rank_map = Map.put(rank_map, node_name, node_rank)
        max_rank = max(rank, node_rank)
        if node_rank == rem(rank - 1, length(Node.list)) do
          Node.monitor(node_name, :true)
        end
        # Declare victory
        coordinator = if rank == max_rank && Map.size(rank_map) == length(Node.list) do
          Enum.map(
            Node.list, fn n -> send({:bully, n}, {:victory, Node.self()}) end)
          Node.self()
        else
          coordinator
        end
        loop(coordinator, rank_map)
      {:victory, coordinator_node} ->
        IO.puts "Coordinator now is #{coordinator_node}"
        loop(coordinator_node, rank_map)
      {:nodedown, node} ->
        dead_rank = Map.get(rank_map, node)
        if dead_rank == max_rank do
          # Coordinator is dead!
          candidates = Enum.filter(rank_map, fn {_, v} -> v > rank end)
                     |> Enum.into(%{})
                     |> Map.keys()
          Enum.map(candidates, fn node -> send({:bully, node}, {:election, Node.self()}) end)
          receive do
            {:ok, _} -> loop(coordinator, rank_map)
            after
              1_000 -> Enum.map(Node.list, fn n -> send({:bully, n}, {:victory, Node.self()}) end)
                       loop(Node.self(), rank_map)
          end

        end
        loop(coordinator, rank_map)
      {:election, caller} ->
        send({:bully, caller}, {:ok, Node.self()})
        Enum.map(
          Node.list, fn n -> send({:bully, n}, {:rank, Node.self(), rank}) end)
        loop(coordinator, rank_map)
    end
  end
end
