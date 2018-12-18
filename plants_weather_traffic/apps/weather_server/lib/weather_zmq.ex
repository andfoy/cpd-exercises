defmodule WeatherZMQ do
  use Agent

  def start_link(args) do
    pid = spawn_link(__MODULE__, :init, args)
    {:ok, pid}
  end

  def init(ip, port) do
    {:ok, socket} = :chumak.socket(:rep, "weather-rep" |> String.to_charlist())

    case :chumak.bind(socket, :tcp, ip |> String.to_charlist(), port) do
      {:ok, _} ->
        loop(socket)

      {:error, reason} ->
        :logger.error("Could not start a ZMQ connection at #{ip}:#{port} - #{reason}")
    end
  end

  defp loop(socket) do
    {:ok, msg} = :chumak.recv(socket)
    {:ok, req} = :msgpack.unpack(msg)
    rep = process_req(req)
    rep = :msgpack.pack(rep)
    :chumak.send(socket, rep)
    loop(socket)
  end

  defp process_req(%{"ping" => "ping"}) do
    %{"pong" => "pong"}
  end

  defp process_req(%{"get_service_info" => "get_service_info"}) do
    %{
      "all_info" => %{
        "input" => %{
          "position" => %{
            "lat" => "number",
            "long" => "number"
          }
        },
        "output" => %{
          "temperature" => "number",
          "humidity" => "number",
          "air_speed" => "number",
          "oxygen_sat" => "number",
          "moon_phase" => "string"
        }
      }
    }
  end

  defp process_req(%{"all_info" => %{"position" => position}}) do
    :logger.debug("I should do something with the position here #{inspect(position)}")

    %{
      "all_info" => %{
        "temperature" => 30,
        "humidity" => 20,
        "air_speed" => 10
      }
    }
  end
end
