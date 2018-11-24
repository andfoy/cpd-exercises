defmodule Files do
  def du(path) do
    IO.inspect(path)
    cond do
      File.regular?(path) ->
        {:ok, %{:size => size}} = File.stat(path)
        size
      File.dir?(path) ->
        dir_files = File.ls!(path)
        case length(dir_files) < 50 do
          true -> Enum.reduce(dir_files, 0,
                              fn x, acc -> du(Path.join(path, x)) + acc end)
          false ->
            len = round(length(dir_files)/2)
            {left_files, right_files} = Enum.split(dir_files, len)
            pid = Task.async(fn -> Enum.reduce(right_files, 0,
                                               fn x, acc -> acc + du(Path.join(path, x)) end) end)
            size_left = Enum.reduce(left_files, 0, fn x, acc -> acc + du(Path.join(path, x)) end)
            size_right = Task.await(pid)
            size_left + size_right
        end
    true -> 0
    end
  end
end
