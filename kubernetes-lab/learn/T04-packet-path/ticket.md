# T04 · Packet path: pod → Service → pod across nodes (Calico VXLAN, kube-proxy, conntrack)
**Learn** · follow one request through routes, VXLAN, iptables and conntrack · ~40 min

Namespace `t04` runs a pod `client` on k8s-w1 and a Deployment `web` (1 replica, agnhost on port 8080) on
k8s-w3 behind the Service `web` (port 80). Follow `client → web:80` and record what you find in
`workspace/T04/answers.yaml`.

1. `kubectl -n t04 get pods,svc,endpointslices -o wide`: the web pod's IP and **node**, the ClusterIP.
2. **kube-proxy** (iptables mode) on k8s-w1: `iptables -t nat -S KUBE-SERVICES | grep t04/web` - the
   **KUBE-SVC chain** of the Service; follow it to its KUBE-SEP chain: the **DNAT target** (`ip:port`).
3. **Routing**: `ip route get <web pod IP>` on k8s-w1 - out through `vxlan.calico`. `ip -d link show
   vxlan.calico`: its **MTU** and **UDP port**. `bridge fdb show dev vxlan.calico`: **which node IP** gets the
   encapsulated packets for the web pod?
4. Watch it: on k8s-w3 `tcpdump -ni enp0s8 udp port <vxlan port>`, then
   `kubectl -n t04 exec client -- /agnhost connect --timeout 3s web:80`. On k8s-w1, `conntrack -L -d
   <ClusterIP>` shows the original and the reply direction of that connection.

**Test**: the 6 answers match the live state (the web pod may move - verify computes it fresh).
