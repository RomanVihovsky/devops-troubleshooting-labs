## Hint 1
Same node works, other nodes don't: the problem is between nodes. How does Calico carry pod traffic between
nodes here? `kubectl get ippools.crd.projectcalico.org -o yaml` (`vxlanMode`), `ip -d link show vxlan.calico` on a
node.

## Hint 2
VXLAN wraps pod packets in **UDP port 4789** between the node IPs. `./lab node w3`, `nft list ruleset | less` - look
for a table that isn't Calico's or kube-proxy's.

## Hint 3
Allow VXLAN from the cluster's nodes before the drop, e.g.
`nft insert rule inet host_firewall input ip saddr 192.168.56.0/24 udp dport 4789 accept`. Keep the table.
