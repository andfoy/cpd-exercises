defmodule LifeCLI do

  @rle_regex :re.compile("((\d*)(b|o))")

  @grid %{0 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          1 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          2 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          3 => %{0 => 0, 1 => 0, 2 => 0, 3 => 1, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          4 => %{0 => 0, 1 => 0, 2 => 1, 3 => 1, 4 => 1, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          5 => %{0 => 0, 1 => 0, 2 => 1, 3 => 0, 4 => 1, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          6 => %{0 => 0, 1 => 0, 2 => 0, 3 => 1, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          7 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          8 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          9 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0},
          10 => %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0}}

  def start(rle_file, steps \\ 100) do
    {:ok, width} = :io.columns
    {:ok, height} = :io.rows
    {rows, cols, grid} = read_rle_file(rle_file)
    simulate(grid, {rows, cols}, {height, width}, steps)
  end

  def example() do
    simulate_grid(@grid, {11, 10}, 20)
  end

  # @spec start(map(), number()) :: map()
  def simulate_grid(grid, {rows, cols}, steps \\ 100) do
    {:ok, width} = :io.columns
    {:ok, height} = :io.rows
    simulate(grid, {rows, cols}, {height, width}, steps)
  end

  defp simulate(grid, {rows, cols}, {height, width}, 0) do
    display(grid, {min(height, rows), min(width, cols)})
    grid
  end

  defp simulate(grid, {rows, cols}, {height, width}, steps) do
    display(grid, {min(height, rows), min(width, cols)})
    grid = Life.life(grid, rows - 1, cols - 1)
    Process.sleep(1000)
    simulate(grid, {rows, cols}, {height, width}, steps - 1)
  end

  defp display(grid, {height, width}) do
    IEx.Helpers.clear
    Enum.each(0..height-1,
              fn i -> Map.get(grid, i)
                   |> Map.take(0..width-1)
                   |> Enum.reduce("", fn {_, v}, acc ->
                      v = case v do
                        1 -> "■"
                        0 -> "□"
                      end
                    "#{acc}#{v}" end)
                   |> IO.puts end)
  end

  defp read_rle_file(rle_file) do
    body = case File.read(rle_file) do
      {:ok, body}      -> String.split(body, "\n")
      {:error, reason} -> :logger.error("#{inspect reason}")
    end
    body = Enum.filter(body, fn line -> not String.starts_with?(line, "#") end)
    [headers | contents] = body
    [[_, rows], [_, cols] | _] = String.split(headers, ", ")
                              |> Enum.map(fn x -> String.split(x, "= ") end)
    {rows, _} = Integer.parse(rows)
    {cols, _} = Integer.parse(cols)
    grid = Enum.reduce(0..rows-1, %{}, fn i, acc ->
                       Map.put(acc , i, Enum.reduce(0..cols-1, %{},
                       fn j, col -> Map.put(col, j, 0) end)) end)

    contents = Enum.reduce(contents, "", fn x, acc -> "#{acc}#{x}" end)
    rles = String.replace(contents, "!", "") |> String.split("$")
    # :logger.info("#{inspect rles}")
    # :logger.info("#{inspect Enum.with_index(rles)}")
    grid = Enum.with_index(rles)
        |> Enum.reduce(grid, fn {rle, pos}, acc ->
                       Map.put(acc, pos, process_rle(rle, Map.get(acc, pos))) end)
    {rows, cols, grid}
  end

  defp process_rle(rle, row) do
    {:ok, re} = @rle_regex
    splits = :re.split(rle, re, [:group, :trim])
    # :logger.info("#{inspect splits}")
    {_, map} = Enum.reduce(splits, {0, row},
                fn [_], {count, map} ->
                  # {num, _} = Integer.parse(num)
                  # map_list = for v <- count..count+num, do: %{v => 0}
                  # map = map_list
                  #    |> Enum.reduce(%{}, fn x, acc -> Map.merge(x, acc) end)
                  #    |> Map.merge(map)
                  {count, map}
                [num, type, _, _], {count, map} ->
                  num = case num do
                    "" -> 1
                    _ -> {num, _} = Integer.parse(num)
                         num
                  end

                  value = case type do
                    "b" -> 0
                    "o" -> 1
                  end
                  # map_list = for v <- count..count+num, do: %{v => value}
                  map = Enum.reduce(count..count+num, map, fn x, acc -> Map.put(acc, x, value) end)
                    #  |> Map.merge(map)
                  {count + num + 1, map}
    end)
    map
  end
end
