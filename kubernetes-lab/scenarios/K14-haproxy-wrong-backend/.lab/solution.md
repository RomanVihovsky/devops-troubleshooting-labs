# K14 - the API load balancer points nowhere

**Root cause**: during the HA preparation the haproxy backend on `k8s-gw` was edited to
`server k8s-cp1 192.168.56.22:6443`, the reserved address of a future cp2 that doesn't exist. haproxy marked
the only server DOWN (its `/readyz` check failed) and closed every connection on :6443. Every client that uses
the control-plane endpoint `k8s-api.lab:6443` lost the API: desktops, and the kubelets (their `kubelet.conf`
uses the endpoint too). They couldn't renew their Leases, so the nodes went NotReady one by one. On cp1, a
kubectl pointed at 192.168.56.21 bypasses the LB.

**Diagnosis**
```
kubectl get nodes -v=6                             # the LB address; EOF / connection reset
curl -s 'http://192.168.56.20:8404/;csv' | cut -d, -f1,2,18     # k8s-cp1 DOWN
./lab node gw; sudo grep -n server /etc/haproxy/haproxy.cfg
./lab node cp1; sudo grep server /etc/kubernetes/kubelet.conf   # https://k8s-api.lab:6443
```

**Fix**: the right backend address, `haproxy -c`, `systemctl reload haproxy`.

**Interview notes**
- `controlPlaneEndpoint` is what makes HA possible later. Everything (kubelets, kubeconfigs, the cluster-info
  ConfigMap) points at the LB, so the LB is now part of the control plane: monitor it, and keep its health
  checks meaningful (`/readyz`, not a bare TCP connect).
- When all nodes go NotReady at once, the node lifecycle controller enters full disruption mode and stops
  evicting pods. Workloads keep running, which is why such an outage looks smaller than it is.
- A `reload` of haproxy keeps established connections on the old process. Long-lived clients (kubelets'
  HTTP/2 connections) kept working until a **restart** cut them. "Half the clients still work" after an LB
  change often means old connections, not a partial fix.
- Check the LB from *both* sides: `curl -k https://<lb>:6443/readyz` and `curl -k https://<cp>:6443/readyz`.
- A typo in an LB config deserves the same review and canary as a code change: `haproxy -c` only checks the
  syntax, not whether the address is right.
