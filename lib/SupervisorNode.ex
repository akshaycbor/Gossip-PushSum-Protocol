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
            if topology == "full" do
                get_full_neighbours(childActors)
            else 
                %{}
            end

        Enum.each( neighbourMap, fn{k,v} ->
            k |> elem(1) |> GenServer.cast({:add_neighbours, v})
        end)
    end

    def add_message(childActors, message) do
        randomNode = Enum.random(childActors)
        randomNode |> elem(1) |> GenServer.call({:add_message, message})
    end


    def get_full_neighbours(childActors) do
        Enum.reduce(childActors, %{}, fn(nodeId, acc) -> Map.put(acc, nodeId, Enum.filter(childActors, fn x -> x != nodeId end)) end)
    end

    def get_line_neighbours(childActors) do
        Enum.reduce(1..length(childActors), %{}, fn(i, acc) ->
            cond do
                i == 1 -> 
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i)])
                i == length(childActors) ->
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i-2)])
                true ->
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i-2), Enum.at(childActors,i)])
            end 
        end)
    end

    def get_imperfect_line_neighbours(childActors) do
        Enum.reduce(1..length(childActors), %{}, fn(i, acc) ->
            cond do
                i == 1 -> 
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i), Enum.random(childActors)])
                i == length(childActors) ->
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i-2), Enum.random(childActors)])
                true ->
                    Map.put(acc, Enum.at(childActors,i-1), [Enum.at(childActors,i-2), Enum.at(childActors,i), Enum.random(childActors)])
            end 
        end)
    end

    def get_torus_neighbours(childActors) do
        n = trunc( :math.sqrt(length(childActors)) )
        n2 = length(childActors)
        Enum.reduce(0..n2-1, %{}, fn(i, acc) ->
            left = 
                if rem(i-1, n) + div(i,n)*n < 0 do
                    n-1
                else
                    rem(i-1, n) + div(i,n)*n    
                end
            
            right = rem(i+1, n) + div(i,n)*n
            up = 
                if rem(i-n, n2) < 0 do
                    n2+(i-n)
                else
                    rem(i-n, n2)
                end
            down = rem(i+n, n2)
            Map.put(acc, Enum.at(childActors, i), 
                [Enum.at(childActors, left),
                 Enum.at(childActors, right),
                 Enum.at(childActors, up),
                 Enum.at(childActors, down)]
            )
        end)
    end
end