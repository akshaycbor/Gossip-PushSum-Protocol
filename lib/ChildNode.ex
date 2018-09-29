defmodule ChildNode do
    use GenServer

    def init(state) do
        {:ok, state}
    end

    def handle_cast({:add_message, message}, {counter, neighbours}) do
        if counter>10 do
            if  counter == 11 do
                [{_, stopped}] = :ets.lookup(:count, "stopped")
                :ets.insert(:count, {"stopped", stopped+1})
            end
            { :noreply, {counter+1, neighbours} }
        else
            if counter == 0 do
                [{_, received}] = :ets.lookup(:count, "received")
                :ets.insert(:count, {"received", received+1})

                GenServer.cast(self(), {:transmit_message, {message, neighbours} })
            end
            { :noreply, {counter+1, neighbours} }
        end
    end

    def handle_cast({:add_neighbours, addtn_neighbours}, {counter, neighbours}) do
        { :noreply, {counter, neighbours ++ addtn_neighbours} }
    end

    def handle_cast({:transmit_message, message }, {counter,neighbours}) do
        if counter>=10 do
            { :noreply, {counter, neighbours} }
        else
            randomNeighbour = Enum.random(neighbours)
            randomNeighbour |> elem(1) |> GenServer.cast({:add_message, message})
            :timer.sleep(1)
            GenServer.cast(self(), {:transmit_message, message})    
            { :noreply, {counter, neighbours} }
        end
    end
end