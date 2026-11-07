## Hint 1
Works from the node, fails from the container. So compare the **container's**
network view with the node's. Enter the container's netns from the node:
`nsenter -n -t $(docker inspect -f '{{.State.Pid}}' <cid>) ip route`
## Hint 2
`ip route get 172.30.0.50` inside the container's namespace: which interface
would the packet leave through? Which network is that interface attached to?
`docker network inspect app_appnet` - look at its subnet.
## Hint 3
The overlay's subnet overlaps the datacenter network, so the legacy API's address
looks "local" to the overlay. Overlay subnets are immutable: change the subnet in
the stack file and recreate the network (`docker stack rm app`, wait, deploy).
