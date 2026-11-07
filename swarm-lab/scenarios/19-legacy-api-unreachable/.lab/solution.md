# Solution - overlay subnet overlaps the datacenter network

**Root cause**: `appnet` uses `172.30.0.0/16`, which contains the datacenter network
`172.30.0.0/24` (nodes, registry, legacy API at 172.30.0.50). Inside the container
the kernel has a connected route `172.30.0.0/16 dev eth0` (the overlay), which is
more specific than the default route. Packets for 172.30.0.50 go into the overlay,
ARP finds nobody, the connection times out. From the node itself, the route is
correct - so "it works from the VM".

**Diagnose** (on a node running billing)
```
pid=$(docker inspect -f '{{.State.Pid}}' <cid>)
nsenter -n -t $pid ip route              # 172.30.0.0/16 dev eth0 ...
nsenter -n -t $pid ip route get 172.30.0.50
docker network inspect -f '{{json .IPAM.Config}}' app_appnet
```

**Fix**: pick a subnet that does not overlap anything you need to reach, e.g.
`10.123.0.0/24`. Network IPAM can't be changed in place:
```
docker stack rm app      # wait until app_appnet is gone
docker stack deploy -c /lab/workspace/stack.yml app
```

**Real-world notes**: the same happens with Docker's default pools (10.0.0.0/8 for
swarm, 172.17-31/16 for bridges) colliding with VPN or office ranges. Set
`docker swarm init --default-addr-pool` and `"default-address-pools"` in
daemon.json up front. Also check `docker_gwbridge` (172.18.0.0/16 by default).
