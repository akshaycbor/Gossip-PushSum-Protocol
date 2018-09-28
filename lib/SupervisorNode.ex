defmodule SupervisorNode do
    use GenServer

    def init(x) do
        {:ok, x}
    end

    def initChildren(numNodes) do
        Enum.map( 1..numNodes, fn(x) ->
            nodeName = String.to_atom("Node#{x}")
            {:ok, pid} = GenServer.start_link(ChildNode, {0, []}, name: nodeName)
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
        randomNode |> elem(1) |> GenServer.call({:add_message, message})
    end

end