defmodule SupervisorNode do
    use GenServer

    def init(x) do
        {:ok, x}
    end

    def initChildren(numNodes) do
        Enum.map( 1..numNodes, fn(x) ->
            nodeName = String.to_atom("Node#{x}")
            {:ok, pid} = GenServer.start_link(ChildNode, [{0, []}, {x, 1, -1, 0}], name: nodeName)
            {String.to_atom("Node#{x}"), pid}
        end)
    end

    def add_neighbours(childActors, topology) do
        neighbourMap = 
            case topology do
                "3Dgrid" -> Topology.get_3dgrid_neighbours(childActors)
                "random2D" -> Topology.get_rand2D_neighbours(childActors)
                "torus" -> Topology.get_torus_neighbours(childActors)
                "line" -> Topology.get_line_neighbours(childActors)
                "impline" -> Topology.get_imperfect_line_neighbours(childActors)
                _ -> Topology.get_full_neighbours(childActors)
            end

        Enum.each( neighbourMap, fn{k,v} ->
            k |> elem(1) |> GenServer.cast({:add_neighbours, v})
        end)
    end

    def add_message(childActors, message) do
        randomNode = Enum.random(childActors)

        :ets.new(:count, [:set, :public, :named_table])
        :ets.insert(:count, {"received", 0})
        :ets.insert(:count, {"stopped", 0})

        start_time = Time.utc_now()
        randomNode |> elem(1) |> GenServer.cast({:add_message, message})
        check_convergence(length(childActors), start_time)
    end

    def check_convergence(numNodes, start_time) do
        
        [{_, received}] = :ets.lookup(:count, "received")
        [{_, stopped}] = :ets.lookup(:count, "stopped")

        if received/numNodes > 0.90 || stopped/numNodes > 0.50 do
            IO.puts("Received #{received}, Stopped #{stopped}, Time taken #{Time.diff(Time.utc_now, start_time, :microsecond)}")
            Process.exit(self(), :kill)
        else
            :timer.sleep(10)
            check_convergence(numNodes, start_time)
        end
    end

    def start_pushsum(childActors) do

        :ets.new(:count, [:set, :public, :named_table])
        :ets.insert(:count, {"dead", 0})

        Enum.map childActors, fn x -> 
            x |> elem(1) |> GenServer.cast({:receive_pushsum_message, 0, 0})
        end

        start_time = Time.utc_now()
        check_pushsum_convergence(length(childActors), start_time)
    end

    def check_pushsum_convergence(numNodes, start_time) do
        [{_, dead}] = :ets.lookup(:count, "dead")

        if dead/numNodes > 0.9 do
            IO.puts("Dead #{dead}, Time taken #{Time.diff(Time.utc_now, start_time, :microsecond)}")
            Process.exit(self(), :kill)
        else
            :timer.sleep(10)
            check_pushsum_convergence(numNodes, start_time)
        end
    end
end