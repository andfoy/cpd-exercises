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

  def life(grid, rows, cols) do
    up_row = Enum.into((for n <- 0..cols, do: {n, 0}), %{})
    down_row = Enum.into((for n <- 0..cols, do: {n, 0}), %{})
    left_col = Enum.into((for n <- 0..rows, do: {n, 0}), %{})
    right_col = Enum.into((for n <- 0..rows, do: {n, 0}), %{})
    step(grid, {0, 0}, {rows, cols}, up_row, down_row, left_col, right_col,
         {0, 0, 0, 0})
  end

  def step(grid, {x, y}, {xw, yh}, up_row, down_row, left_col, right_col,
           {ul_cor, ur_cor, ll_cor, lr_cor}) do
    h = xw - x
    w = yh - y
    if h * w <= 6 * 6 do
      update(grid, {x, y}, {xw, yh}, up_row,
             down_row, left_col, right_col,
             {ul_cor, ur_cor, ll_cor, lr_cor})
    else
      x_mid = Kernel.trunc((x + xw) / 2)
      y_mid = Kernel.trunc((y + yh) / 2)
      first_half = Map.take(grid, (for m <- x..x_mid, do: m))
      second_half = Map.take(grid, (for m <- x_mid + 1..xw, do: m))
      upper_left = Enum.map(first_half, fn {k, v} -> {k, Map.take(v, (for m <- y..y_mid, do: m))} end)
                |> Enum.into(%{})
      upper_right = Enum.map(first_half, fn {k, v} -> {k, Map.take(v, (for m <- y_mid+1..yh, do: m))} end)
                  |> Enum.into(%{})
      lower_left = Enum.map(second_half, fn {k, v} -> {k, Map.take(v, (for m <- y..y_mid, do: m))} end)
                 |> Enum.into(%{})
      lower_right = Enum.map(second_half, fn {k, v} -> {k, Map.take(v, (for m <- y_mid+1..yh, do: m))} end)
                  |> Enum.into(%{})


      up_row_1 = Map.take(up_row, (for m <- y..y_mid, do: m))
      up_row_2 = Map.take(up_row, (for m <- y_mid+1..yh, do: m))

      down_row_1 = Map.take(down_row, (for m <- y..y_mid, do: m))
      down_row_2 = Map.take(down_row, (for m <- y_mid+1..yh, do: m))

      left_col_1 = Map.take(left_col, (for m <- x..x_mid, do: m))
      left_col_2 = Map.take(left_col, (for m <- x_mid+1..xw, do: m))

      right_col_1 = Map.take(right_col, (for m <- x..x_mid, do: m))
      right_col_2 = Map.take(right_col, (for m <- x_mid+1..xw, do: m))


      up_mid_row_1 = Map.get(upper_left, x_mid)
      down_mid_row_1 = Map.get(lower_left, x_mid + 1)
      up_mid_row_2 = Map.get(upper_right, x_mid)
      down_mid_row_2 = Map.get(lower_right, x_mid + 1)

      left_mid_col_1 = Enum.map(upper_left, fn {k, v} -> {k, Map.get(v, y_mid)} end)
                    |> Enum.into(%{})
      left_mid_col_2 = Enum.map(lower_left, fn {k, v} -> {k, Map.get(v, y_mid)} end)
                    |> Enum.into(%{})

      right_mid_col_1 = Enum.map(upper_right, fn {k, v} -> {k, Map.get(v, y_mid + 1)} end)
                    |> Enum.into(%{})
      right_mid_col_2 = Enum.map(lower_right, fn {k, v} -> {k, Map.get(v, y_mid + 1)} end)
                     |> Enum.into(%{})

      up_l_ll_cor = Map.get(left_col, x_mid + 1)
      up_l_lr_cor = Map.get(down_mid_row_2, y_mid + 1)
      up_l_ur_cor = Map.get(up_row_2, y_mid + 1)
      up_l = Task.async(fn -> step(upper_left, {x, y}, {x_mid, y_mid},
                                   up_row_1, down_mid_row_1, left_col_1, right_mid_col_1,
                                   {ul_cor, up_l_ur_cor, up_l_ll_cor, up_l_lr_cor}) end)
      up_r_ul_cor = Map.get(up_row_1, y_mid)
      up_r_ll_cor = Map.get(down_mid_row_1, y_mid)
      up_r_lr_cor = Map.get(right_col_2, x_mid + 1)
      up_r = Task.async(fn -> step(upper_right, {x, y_mid + 1}, {x_mid, yh},
                                   up_row_2, down_mid_row_2, left_mid_col_1, right_col_1,
                                   {up_r_ul_cor, ur_cor, up_r_ll_cor, up_r_lr_cor}) end)
      dn_l_ul_cor = Map.get(left_col_2, x_mid + 1)
      dn_l_lr_cor = Map.get(down_row_2, y_mid + 1)
      dn_l_ur_cor = Map.get(up_mid_row_2, y_mid + 1)
      dn_l = Task.async(fn -> step(lower_left, {x_mid + 1, y}, {xw, y_mid},
                                   up_mid_row_1, down_row_1, left_col_2, right_mid_col_2,
                                   {dn_l_ul_cor, dn_l_ur_cor, ll_cor, dn_l_lr_cor}) end)
      dn_r_ul_cor = Map.get(up_mid_row_1, y_mid)
      dn_r_ur_cor = Map.get(right_col_1, x_mid)
      dn_r_ll_cor = Map.get(down_row_1, y_mid)
      lower_right = step(lower_right, {x_mid + 1, y_mid + 1}, {xw, yh},
                         up_mid_row_2, down_row_2, left_mid_col_2, right_col_2,
                         {dn_r_ul_cor, dn_r_ur_cor, dn_r_ll_cor, lr_cor})
      upper_left = Task.await(up_l)
      upper_right = Task.await(up_r)
      lower_left = Task.await(dn_l)
      upper_half = Map.merge(upper_left, upper_right, fn _k, v1, v2 -> Map.merge(v1, v2) end)
      lower_half = Map.merge(lower_left, lower_right, fn _k, v1, v2 -> Map.merge(v1, v2) end)
      Map.merge(upper_half, lower_half)
    end
  end

  def update(grid, {x, y}, {xw, yh}, up_row,
             down_row, left_col, right_col,
             {ul_cor, ur_cor, ll_cor, lr_cor}) do
    up_row = Map.put(up_row, y - 1, ul_cor)
    up_row = Map.put(up_row, yh + 1, ur_cor)
    down_row = Map.put(down_row, y - 1, ll_cor)
    down_row = Map.put(down_row, yh + 1, lr_cor)
    grid2 = Enum.map(grid,
                    fn {i, row} -> {i, Map.put(row, y - 1, Map.get(left_col, i))} end)
         |> Enum.into(%{})
    grid2 = Enum.map(grid2,
                    fn {i, row} -> {i, Map.put(row, yh + 1, Map.get(right_col, i))} end)
         |> Enum.into(%{})
    grid2 = Map.put(grid2, x - 1, up_row)
    grid2 = Map.put(grid2, xw + 1, down_row)
    Enum.map(grid, fn {i, row} -> {i, Enum.map(row,
      fn {j, value} ->
        {j, apply_rules(i, j, value, grid2)}
      end
    ) |> Enum.into(%{})} end) |> Enum.into(%{})
  end

  def apply_rules(i, j, value, grid) do
    sum = neighborhood_sum(i, j, grid)
    case value do
      0 -> if sum == 3 do 1 else 0 end
      1 -> case sum do
        3 -> 1
        4 -> 1
        _ -> 0
      end
    end
  end

  def neighborhood_sum(i, j, grid) do
    values = (for off1 <- -1..1, do: (for off2 <- -1..1, do:
              Map.get(grid, i + off1) |> Map.get(j + off2)))
    Enum.reduce(values, 0, fn x, acc -> Enum.reduce(x, fn y, s -> y + s end) + acc end)
  end

end
