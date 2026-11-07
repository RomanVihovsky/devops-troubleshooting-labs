## Hint 1
Map it out: which node runs which task (`docker service ps app_web app_redis`)?
Which node *combinations* fail? Same-node traffic vs cross-node traffic?
## Hint 2
Cross-node container traffic in swarm rides **VXLAN** (UDP 4789) between nodes;
the control plane uses TCP 2377 and gossip TCP/UDP 7946. Watch the wire on the
suspicious node: `tcpdump -ni eth0 udp port 4789` while you curl. Packets arrive... and then?
## Hint 3
Something on that node is dropping inbound UDP 4789. `iptables -L` only shows the
default table - use `iptables-save` (or `iptables -L -n -v` and follow the custom chains).
