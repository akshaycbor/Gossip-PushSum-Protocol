defmodule GossipPushsum do

    @moduledoc """
    Starts the SupervisorNode for the Gossip or Push sum
    """

    def init(numNodes, topology, algorithm) do
        
        if algorithm != "gossip" && algorithm != "pushsum" do
            IO.puts("Invalid input")
        end

        children = SupervisorNode.initChildren(numNodes)
        SupervisorNode.add_neighbours(children, topology)

        if algorithm == "gossip" do
            SupervisorNode.add_message(children, "Gossip!")
        else
            SupervisorNode.start_pushsum(children)
        end
    end
end
