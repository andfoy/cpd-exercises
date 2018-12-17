defmodule PlantsServer do
  use GenServer

  defp get_address() do
    :inet.getifaddrs()
    |> elem(1)
    |> Enum.reduce_while({}, fn {_interface, attr}, acc ->
      case attr |> get_ipv4 do
        false -> {:cont, acc}
        {} -> {:cont, acc}
        {_, _, _, _} = add -> {:halt, add}
      end
    end)
  end

  defp get_ipv4(attr) do
    case attr |> Keyword.get_values(:addr) do
      [] ->
        false

      l ->
        l
        |> Enum.reduce_while({}, fn ip, acc ->
          case ip do
            {127, 0, 0, 1} -> {:cont, acc}
            {_, _, _, _, _, _, _, _} -> {:cont, acc}
            {_, _, _, _} = add -> {:halt, add}
          end
        end)
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [%{:weather => nil}], name: :plants)
  end

  defp recieve_scan_responses do
    receive do
      {:"_plants._tcp.local", msg} ->
        :logger.debug("msg: #{inspect(msg)}")
        # code
    after
      1_000 -> :nothing
    end
    Process.sleep(2000)
    Mdns.Client.query("_plants._tcp.local")
    recieve_scan_responses()
  end

  defp start_mdns_scan() do
    Mdns.Client.start()
    :logger.debug("PID: #{inspect(self())}")
    # Mdns.EventManager.register()
    Mdns.EventManager.add_handler()
    # Mdns.Client.query("_plants._tcp.local")
    Mdns.Client.query("_plants._tcp.local")
    # Mdns.Client.query("_ssh._tcp.local")
    recieve_scan_responses()
  end

  def init(services) do
    address = get_address()
    # address = {10, 241, 139, 78}
    :logger.debug("#{inspect(address)}")
    Application.ensure_all_started(Mdns.Server)
    Mdns.Server.start()
    Mdns.Server.set_ip(address)

    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: "machine.local",
      data: :ip,
      ttl: 10,
      type: :a
    })

    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: "_plants._tcp.local",
      data: "_plants._tcp.local",
      ttl: 10,
      type: :ptr
    })

    char_host = "machine.local" |> String.to_charlist()
    lookup = :inet.gethostbyname(char_host, :inet)
    :logger.debug("Lookup #{inspect(lookup)}")
    {:ok, {:hostent, ^char_host, [], :inet, 4, [^address]}} = lookup
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: "_plants._tcp.local",
      data: ["id=123123", "port=8800"],
      ttl: 10,
      type: :txt
    })
    Task.async(fn -> start_mdns_scan() end)
    {:ok, services}
  end
end
