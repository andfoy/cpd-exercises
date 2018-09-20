defmodule Functional do
  defp partition(l, pivot) do
    partition(l, pivot, [], [])
  end
  defp partition([h | t], pivot, l, r) when h > pivot do
      partition(t, pivot, l, [h | r])
  end
  defp partition([h | t], pivot, l, r) when h <= pivot do
    partition(t, pivot, [h | l], r)
  end
  defp partition([], _, l, r) do {l, r} end

  def quicksort([_] = list) do list end
  def quicksort([]) do [] end
  def quicksort(l) do
    pivot = Enum.random(l)
    {l, r} = partition(l, pivot)
    l = quicksort(l)
    r = quicksort(r)
    l ++ r
  end

end
