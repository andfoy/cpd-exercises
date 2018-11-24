defmodule Life do
  @moduledoc """
  Documentation for Life.
  """
  @grid %{0 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0},
          1 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0},
          2 => %{0 => 0, 1 => 0, 2 => 0, 3 => 1, 4 => 0, 5 => 0, 6 => 0, 7 => 0},
          3 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 1, 5 => 0, 6 => 0, 7 => 0},
          4 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 1, 5 => 0, 6 => 0, 7 => 0},
          5 => %{0 => 0, 1 => 0, 2 => 1, 3 => 1, 4 => 1, 5 => 0, 6 => 0, 7 => 0},
          6 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0},
          7 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0}}

  def step(grid) do

  end

  def life(grid, top_corner, down_corner, right_neigh) do
    {x, y} = top_corner
    {xh, yw} = down_corner
    h = xh - x
    w = yw - y
    if h * w <= 36 do
      step(grid)
    else
      x_mid = Kernel.trunc((x + xh) / 2)
      y_mid = Kernel.trunc((y + yw) / 2)
      first_half = Map.take(grid, (for m <- x..x_mid, do: m))
      second_half = Map.take(grid, (for m <- x_mid + 1..xh, do: m))
      upper_left = Enum.each(first_half, fn {k, v} -> {k, Map.take(v, (for m <- y..y_mid, do: m))} end)
                |> Enum.into(%{})
      upper_right = Enum.each(first_half, fn {k, v} -> {k, Map.take(v, (for m <- y_mid+1..yw, do: m))} end)
                  |> Enum.into(%{})
      lower_left = Enum.each(second_half, fn {k, v} -> {k, Map.take(v, (for m <- y..y_mid, do: m))} end)
                |> Enum.into(%{})
      lower_right = Enum.each(first_half, fn {k, v} -> {k, Map.take(v, (for m <- y_mid+1..yw, do: m))} end)
                  |> Enum.into(%{})
    end
  end

  def life(grid) do
    rows = Map.size(grid)
    cols = Map.size(Map.get(grid, 0))
    life(grid, {0, 0}, {rows - 1, cols - 1})
  end
end
