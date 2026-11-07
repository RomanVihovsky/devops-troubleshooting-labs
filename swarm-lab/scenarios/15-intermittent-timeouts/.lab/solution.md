# Solution - firewall drops VXLAN (UDP 4789) on one node

**Root cause**: a "hardening" chain `SEC-BASELINE` on worker2 allows the swarm
control plane (TCP 2377) and gossip (7946) but drops all other inbound high UDP
ports - including **UDP 4789 (VXLAN data plane)**. So:
- nodes stay `Ready` (2377 works), services look healthy;
- any container traffic *into* worker2 from another node is lost: the routing mesh
  sending to a task on worker2, or worker2's web reaching redis elsewhere (replies are lost).
Round-robin over IPVS makes it look random.

**Diagnose**
```
docker service ps app_web app_redis          # who runs where
# on worker2 while curling:
tcpdump -ni eth0 udp port 4789               # packets arrive, nothing answers
iptables-save | grep -n -e SEC-BASELINE -e DROP
iptables -L SEC-BASELINE -n -v               # DROP counter increasing
```

**Fix**: allow VXLAN from the other swarm nodes (keep the hardening):
```
iptables -I SEC-BASELINE 1 -p udp --dport 4789 -j RETURN
```
Required ports between swarm nodes: TCP 2377, TCP+UDP 7946, UDP 4789 (+ IP proto 50 if
overlays are `encrypted`).

**Emulation**: `iptables` inside worker2's network namespace (the node container).
**Real-world notes**: same symptom from cloud security groups, VMware NSX, or a NIC
doing VXLAN offload on 4789 for its own use (then use `--data-path-port`).
