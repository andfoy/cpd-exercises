defmodule HOF do
  def map([h | t], lambda) do
    [ lambda.(h) | map(t, lambda) ]
  end
  def map([], _) do [] end

  def reduce([h | t], lambda, accum) do
    reduce(t, lambda, lambda.(accum, h))
  end
  def reduce([], _, accum) do accum end

  def map_join(list, joiner \\ "", mapper) do
    [first | list_map] = map(list, mapper)
    reduce(list_map, &("#{&1}#{joiner}#{&2}"), first)
  end

  def map_reduce(list, acc, lambda) do
    map_reduce(list, [], acc, lambda)
  end
  def map_reduce([h | t], l_accum, acc, lambda) do
    {h, acc} = lambda.(h, acc)
    map_reduce(t, [h | l_accum], acc, lambda)
  end
  def map_reduce([], l_accum, acc, _) do
    {Enum.reverse(l_accum), acc}
  end
end
