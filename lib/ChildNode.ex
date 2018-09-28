defmodule ChildNode do
    use GenServer

    def init(state) do
        {:ok, state}
    end

    def handle_call({:add_message, message}, _, {counter, neighbours}) do
        if counter>10 do
            { :reply, :dead, {counter, neighbours} }
        else
            if counter == 0 do
                GenServer.cast(self(), {:transmit_message, {message, neighbours} })
            end
            { :reply, :alive, {counter+1, neighbours} }
        end
    end

    def handle_cast({:add_neighbours, addtn_neighbours}, {counter, neighbours}) do
        { :noreply, {counter, neighbours ++ addtn_neighbours} }
    end

    def handle_cast({:transmit_message, {message,valid_neighbours} }, {counter,neighbours}) do
        if counter>=10 do
            { :noreply, {counter, neighbours} }
        else
            if valid_neighbours != [] do
                randomNeighbour = Enum.random(valid_neighbours)
                resp = randomNeighbour |> elem(1) |> GenServer.call({:add_message, message})
                valid_neighbours =
                    if resp == :dead do
                        valid_neighbours -- [randomNeighbour]
                    else
                        valid_neighbours
                    end
                :timer.sleep(1)
                GenServer.cast(self(), {:transmit_message, {message, valid_neighbours}})    
            end
            { :noreply, {counter, neighbours} }
        end
    end
end