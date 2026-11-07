## Hint 1
Small packets work, big transfers stall right after the headers. Which property of
a path affects only *large* packets? Where do the `files` tasks run, and which path
does a request via worker2 take (`docker service ps app_files`)?
## Hint 2
Probe the path between nodes with the DF bit set:
`ping -M do -s 1472 -c2 172.30.0.22` (from manager1/worker1), then smaller sizes.
Compare `ip link show eth0` on all nodes.
## Hint 3
VXLAN adds 50 bytes: overlay MTU 1450 + 50 = 1500-byte frames on the underlay.
If one node's interface accepts less than that, big overlay packets towards it are
silently dropped. Restore the MTU (`ip link set eth0 mtu ...`) - or, if the network
really is smaller, lower the overlay MTU (`com.docker.network.driver.mtu`).
