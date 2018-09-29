defmodule Topology do
    
    @moduledoc """
    Arranges a list of nodes in the specified topology.
    All Public functions return a mapping of every node to their corresponding neighbours 
    """

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
        n2 = n*n
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

    def get_rand2D_neighbours(childActors) do
        childCoordinates = Enum.map(childActors, fn(x) ->
            {x, :rand.uniform(100)/100, :rand.uniform(100)/100}
        end)
        Enum.reduce(childCoordinates, %{}, fn(x, acc) ->
            Map.put(acc, elem(x,0), Enum.reduce(childCoordinates, [], fn(y, list_acc) ->
                list_acc ++ 
                    if y != x && within_d_distance?(x, y, 0.1) do
                        [elem(y,0)]
                    else
                        []
                    end
                end)
            )
        end)
    end

    defp within_d_distance?(childCoordinate1, childCoordinate2, d) do
        {x1,y1, x2,y2} = {elem(childCoordinate1,1),elem(childCoordinate1,2), elem(childCoordinate2,1),elem(childCoordinate2,2) }
        (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) <= d*d 
    end

    def get_3dgrid_neighbours(childActors) do

        # Get the dimensions of the 3d grid
        factors = get_divisors(length(childActors))
        a = Enum.at(factors, div(length(factors),2))
        remainder_factors = get_divisors( div(length(childActors),a ))
        b = Enum.at(remainder_factors, div( length(remainder_factors),2 ))
        c = div(length(childActors), a*b)

        n = a
        n2 = a*b
        n3 = a*b*c

        Enum.reduce( 1..length(childActors), %{}, fn(x,acc) ->
            neighbours = []
            # up
            neighbours = neighbours ++ if rem(x,n2) < n, do: [], else: [Enum.at(childActors, x-n)]
            
            # down
            neighbours = neighbours ++ if n2-rem(x,n2)-1 < n, do: [], else: [Enum.at(childActors, x+n)]

            # left
            neighbours = neighbours ++ if rem(x,n) == 0, do: [], else: [Enum.at(childActors, x-1)]

            # right
            neighbours = neighbours ++ if n-rem(x,n)-1 == 0, do: [], else: [Enum.at(childActors, x+1)]

            # backwards
            neighbours = neighbours ++ if rem(x,n3) < n2, do: [], else: [Enum.at(childActors, x-n2)]

            # forwards
            neighbours = neighbours ++ if n3-rem(x,n3)-1 < n2, do: [], else: [Enum.at(childActors, x+n2)]

            Map.put(acc, Enum.at(childActors, x), neighbours)
        end)
    end

    # Returns list of all factors of an integer -> https://rosettacode.org/wiki/Factors_of_an_integer#Elixir
    defp get_divisors(n), do: divisor(n, 1, []) |> Enum.sort
 
    defp divisor(n, i, factors) when n < i*i    , do: factors
    defp divisor(n, i, factors) when n == i*i   , do: [i | factors]
    defp divisor(n, i, factors) when rem(n,i)==0, do: divisor(n, i+1, [i, div(n,i) | factors])
    defp divisor(n, i, factors)                 , do: divisor(n, i+1, factors)

end