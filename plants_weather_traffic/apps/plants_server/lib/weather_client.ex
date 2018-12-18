defmodule Plants.WeatherClient do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, {nil, %{}}}
  end

  def start_socket(ip, port) do
    GenServer.call(__MODULE__, {:socket, ip, port})
  end

  def request(request_type, request_body) do
    GenServer.call(__MODULE__, {request_type, request_body})
  end

  defp await_reply(sock) do
    case :chumak.recv(sock) do
      {:ok, response} ->
        {:ok, response} = :msgpack.unpack(response)
        {:ok, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_msg(request, sock) do
    msg = :msgpack.pack(request)

    case :chumak.send(sock, msg) do
      :ok ->
        await_reply(sock)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_socket(ip, port) do
    {:ok, sock} = :chumak.socket(:req, "weather-req" |> String.to_charlist())
    :logger.debug("Connecting to ZMQ client at #{inspect ip}:#{inspect port}")
    case :chumak.connect(sock, :tcp, ip |> String.to_charlist(), port) do
      {:ok, _pid} ->
        {:ok, sock}

      {:error, reason} ->
        :logger.error("Connection failed: #{inspect(reason)}")
        {:error, nil}
    end
  end

  defp request_service_info(ip, port) do
    case create_socket(ip, port) do
        {:ok, sock} ->
          case send_msg(%{"get_service_info" => "get_service_info"}, sock) do
            {:ok, response} ->
              :logger.debug("Service info: #{inspect response}")
              {sock, response}
            {:error, _} -> {nil, %{}}
          end
        {:error, _} -> {nil, %{}}
      end
  end

  defp send_msg_reply(request, {sock, services}) do
    case send_msg(request, sock) do
      {:ok, response} -> {:reply, response, {sock, services}}
      {:error, reason} -> :logger.error("Error while sending request: #{inspect(reason)}")
                         {:reply, :error, {nil, %{}}}
    end
  end

  defp check_types(value, signature_type) when is_map(value) and is_bitstring(signature_type) do
    :false
  end

  defp check_types(value, signature_type) when is_bitstring(signature_type) do
    case signature_type do
      "number" -> is_number(value)
      "string" -> is_bitstring(value)
    end
  end

  defp check_types(value, signature_type) when is_map(value) and is_map(signature_type) do
    signature_match(value, signature_type)
  end

  defp signature_match(body, signature) do
    Enum.reduce_while(body, :true, fn {k, v}, acc ->
      case Map.has_key?(signature, k) do
        :true ->
          case check_types(v, Map.get(signature, k)) do
            :true -> {:cont, acc}
            :false -> {:halt, acc}
          end
        :false -> {:halt, acc}
      end
    end)
  end

  defp isalive(sock) do
    ping = :msgpack.pack(%{"ping" => "ping"})
    :chumak.send(sock, ping)
    case :chumak.recv(sock) do
      {:ok, _} -> :true
      {:error, _} -> :false
    end
  end

  def handle_call({:socket, ip, port}, _from, {nil, %{}}) do
    info = request_service_info(ip, port)
    {:reply, :ok, info}
  end


  def handle_call({:socket, ip, port}, _from, {sock, services}) do
    alive = isalive(sock)
    :logger.debug("Socket is alive: #{inspect alive}")
    case alive do
      :true -> {:reply, :ok, {sock, services}}
      :false -> {:reply, :ok, request_service_info(ip, port)}
    end
  end

  def handle_call({request_type, request_body}, _from, {sock, services}) do
    type = request_type
        |> Atom.to_string()
    # request_body = elem(request, 1)
    case Map.has_key?(services, type) do
      :true ->
        signature = Map.get(services, type)
        case signature_match(request_body, Map.get(signature, "input")) do
          :true -> send_msg_reply(%{type => request_body}, {sock, services})
          :false -> {:reply, :error, {sock, services}}
        end
    end
  end
end
