defmodule ChildNode do
    use GenServer

    def init(state) do
        {:ok, state}
    end

    def handle_cast({:add_neighbours, addtn_neighbours}, [{gossipCounter, neighbours}, state]) do
        { :noreply, [{gossipCounter, neighbours ++ addtn_neighbours}, state] }
    end

    @doc """
    Gossip fn -> Receives the message and starts transmitting to neighbours according to the gossip protocol
    """
    def handle_cast({:add_message, message}, [{gossipCounter, neighbours}, state]) do
        if gossipCounter>10 do
            if  gossipCounter == 11 do
                [{_, stopped}] = :ets.lookup(:count, "stopped")
                :ets.insert(:count, {"stopped", stopped+1})
                Process.exit(self(), :normal)
            end
            { :noreply, [{gossipCounter+1, neighbours}, state] }
        else
            if gossipCounter == 0 do
                [{_, received}] = :ets.lookup(:count, "received")
                :ets.insert(:count, {"received", received+1})

                GenServer.cast(self(), {:transmit_message, message })
            end
            { :noreply, [{gossipCounter+1, neighbours}, state] }
        end
    end

    @doc """
    Gossip fn -> Periodcally transmits gossip message to a random neighbour after receiving it once
    """
    def handle_cast({:transmit_message, message }, [{gossipCounter,neighbours}, state]) do
        if gossipCounter>=10 do
            { :noreply, [{gossipCounter, neighbours}, state] }
        else
            neighbours = Enum.filter(neighbours, fn x -> Process.alive? elem(x,1) end)
            if neighbours == [] do
                [{_, stopped}] = :ets.lookup(:count, "stopped")
                :ets.insert(:count, {"stopped", stopped+1})
                Process.exit(self(), :normal)
            end
            randomNeighbour = Enum.random(neighbours)
            randomNeighbour |> elem(1) |> GenServer.cast({:add_message, message})
            :timer.sleep(10)
            GenServer.cast(self(), {:transmit_message, message})    
            { :noreply, [{gossipCounter, neighbours}, state] }
        end
    end

    @doc """
    Pushsum fn -> Receives s, w from other nodes and adds it to its owm
    """
    def handle_cast({:receive_pushsum_message, s2, w2}, [{gossipCounter, neighbours}, {s, w, old_ratio, pushsumCounter}]) do
        
        if old_ratio == -1 do
            schedule_transmission()
        end
        {:noreply, [{gossipCounter, neighbours}, { s+s2, w+w2, old_ratio, pushsumCounter }]}
    end

    @doc """
    Periodically transmits half its s & w to random (alive)neighbour
    """
    def handle_info({:transmit_pushsum_message}, [{gossipCounter, neighbours}, {s, w, old_ratio, pushsumCounter}] ) do

        neighbours = Enum.filter(neighbours, fn x -> Process.alive? elem(x,1) end)
        if neighbours == [] do
            IO.puts("Ratio #{s/w}")
            [{_, dead}] = :ets.lookup(:count, "dead")
            :ets.insert(:count, {"dead", dead+1})
            Process.exit(self(), :normal)
        end

        {s, w} = {s/2, w/2}
        Enum.random(neighbours) |> elem(1) |> GenServer.cast({:receive_pushsum_message, s, w})

        pushsumCounter = pushsumCounter + if abs(s/w - old_ratio) < 0.0000000001, do: 1, else: -pushsumCounter
        if pushsumCounter >= 3 do
            [{_, dead}] = :ets.lookup(:count, "dead")
            :ets.insert(:count, {"dead", dead+1})
            IO.puts("Ratio #{s/w}")
            Process.exit(self(), :normal)
        end

        schedule_transmission()
        {:noreply, [{gossipCounter, neighbours}, {s, w, s/w, pushsumCounter}]}
    end

    defp schedule_transmission() do
        Process.send_after(self(), {:transmit_pushsum_message}, 100) # In 100 milliseconds
    end
end