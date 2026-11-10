# L05 - the kubelet talks to the wrong endpoint

**Root cause**: `/etc/kubernetes/kubelet.conf` on k8s-w1 has `server: https://k8s-api.lab:6444`. The kubelet
can't reach the API: no node status, no lease renewals - after `node-monitor-grace-period` (40 s) the
controller-manager marks it NotReady (Unknown), and after 5 min the pods get evicted.

**Diagnosis**: `kubectl describe node k8s-w1` (Kubelet stopped posting node status); on the node
`journalctl -u kubelet` (dial tcp ...:6444: connection refused), `grep server: /etc/kubernetes/kubelet.conf`.

**Fix**: the right URL, restart the kubelet.

**Interview notes**
- Node → API goes through `controlPlaneEndpoint` (here haproxy on k8s-gw); changing the control plane's
  address means updating every kubelet.conf, the `cluster-info` ConfigMap (used by joins) and kube-proxy's
  kubeconfig - and the API server cert SANs.
- NotReady with reason "Unknown" = the node stopped reporting; NotReady with a reason = the kubelet reports
  a problem (runtime, network, pressure).
