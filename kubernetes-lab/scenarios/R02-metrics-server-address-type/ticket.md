# kubectl top: "metrics not available yet"
**INC-2520** · P2 · Reporter: platform team

Since this morning `kubectl top nodes` says *metrics not available yet* (or *the server is currently unable to
handle the request*), and HPAs show `<unknown>`. Last night someone "simplified" the metrics-server flags
(Deployment `kube-system/metrics-server`). We verify kubelet certificates - the fix must not turn that off.

**Test**: `kubectl top nodes` lists all 4 nodes; metrics-server reaches the kubelets by their InternalIP first;
it still verifies the kubelets' TLS certificates (no `--kubelet-insecure-tls`).
