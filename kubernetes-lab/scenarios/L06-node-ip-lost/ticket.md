# logs and exec broken for everything on k8s-w2
**INC-2316** · P3 · Reporter: developers

`kubectl logs` and `kubectl exec` time out for every pod on k8s-w2 - only there. The pods run and serve
fine. Yesterday someone "simplified the kubelet flags" on k8s-w2 (`/var/lib/kubelet/kubeadm-flags.env`)
and restarted it. The node had been re-provisioned last week, from the stock cloud image.

**Test**: k8s-w2's InternalIP is 192.168.56.32 again; `kubectl logs` works for its pods; it is Ready.
