defmodule AstroZMQ do
  use Agent

  def start_link(args) do
    pid = spawn_link(__MODULE__, :init, args)
    {:ok, pid}
  end

  def init(ip, port) do
    {:ok, socket} = :chumak.socket(:rep, "astro-rep" |> String.to_charlist())

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
      "moon_phase" => %{
        "input" => %{
          "position" => %{
            "lat" => "number",
            "long" => "number"
          }
        },
        "output" => %{
          "moon_phase" => "string"
        }
      }
    }
  end

  defp process_req(%{"moon_phase" => %{"position" => position}}) do
    :logger.debug("I should do something with the position here #{inspect(position)}")
    %{
      "moon_phase" => "full"
    }
  end
end
