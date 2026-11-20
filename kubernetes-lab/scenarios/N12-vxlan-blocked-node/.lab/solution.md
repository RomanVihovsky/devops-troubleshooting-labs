# N12 - a host firewall drops the overlay

**Root cause**: Calico runs in **VXLAN** mode here: a pod packet to another node is wrapped in UDP to port **4789**
on the other node's IP (`vxlan.calico` device). w3's new `host_firewall` table drops every UDP packet from the
node network except DNS/NTP, so encapsulated traffic from other nodes never reaches w3's pods - and replies from
w3's pods to other nodes come back as VXLAN and are dropped too. Same-node traffic never leaves the host.

**Diagnosis**
```
kubectl get pods -A -o wide | grep k8s-w3                   # pick pods on w3 and elsewhere
kubectl -n meshcheck exec <pod-on-w1> -- labapp get http://<pod-on-w3-ip>:8080/health    # timeout
./lab node w3
  nft list ruleset | grep -B3 -A6 host_firewall
  nft list table inet host_firewall                         # counter increasing
  tcpdump -ni enp0s8 udp port 4789                          # packets arrive, pods never see them
```

**Fix**: keep the policy, allow the overlay between nodes:
`nft insert rule inet host_firewall input ip saddr 192.168.56.0/24 udp dport 4789 accept`
(and make it persistent wherever the firewall is managed).

**Interview notes**
- Overlay ports: VXLAN 4789/udp (Calico, Flannel 8472 on Linux), IP-in-IP = IP protocol 4, WireGuard 51820/udp,
  BGP 179/tcp, Geneve 6081/udp (Cilium/OVN).
- "Same node works, other nodes don't" => node-to-node path: firewall, MTU (encapsulation overhead), wrong node
  IP for the tunnel (X07), cloud security groups.
- MTU problems look similar but small requests work and large ones hang.
