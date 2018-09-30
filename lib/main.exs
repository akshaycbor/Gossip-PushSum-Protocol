# Reads arguments from cmd and passes them to Gossip module
{numNodes, topology, algorithm} = List.to_tuple(System.argv)
GossipPushsum.init(String.to_integer(numNodes), topology, algorithm)