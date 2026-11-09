# T04 - solution and takeaways

```
web_node: k8s-w3                 kubectl -n t04 get pods -o wide
svc_chain: KUBE-SVC-...          iptables -t nat -S KUBE-SERVICES | grep t04/web     (on k8s-w1)
dnat_target: <web pod IP>:8080   iptables -t nat -S KUBE-SEP-...
vxlan_mtu: 1450                  ip -d link show vxlan.calico
vxlan_port: 4789                 ip -d link show vxlan.calico   (dstport)
vxlan_peer: 192.168.56.33        bridge fdb show dev vxlan.calico
```

**The path of `client → web:80`**
1. The client resolves `web` → ClusterIP (CoreDNS; search domains, `ndots:5`).
2. In k8s-w1's netfilter (`PREROUTING`/`OUTPUT` → `KUBE-SERVICES` → `KUBE-SVC-*` → `KUBE-SEP-*`) the
   destination ClusterIP:80 is DNATed to podIP:8080. conntrack remembers it, so replies are un-NATed.
3. Routing: the pod IP lies in a /26 block that Calico assigned to k8s-w3 → `via <w3 tunnel IP> dev
   vxlan.calico`.
4. The VXLAN device wraps the frame in UDP/4789 to k8s-w3's host-only IP (from the fdb); k8s-w3 unwraps
   it and delivers it to the pod's `cali*` veth.

**Takeaways**
- "Service doesn't work" splits into: endpoints (selector/readiness), DNS, kube-proxy rules, routing/CNI,
  NetworkPolicy - check them in that order (N and X domains).
- MTU: the overlay costs 50 bytes. A pod MTU larger than the path allows = small requests work, large
  responses hang (L18-style incidents).
- `conntrack -L` / `conntrack -D` matter when backends change under long-lived UDP flows (DNS races).
