# B02 - three control-plane faults at once

1. **kube-scheduler**: `- --v=4` was added with a **TAB**. The kubelet can't parse the manifest, so the static pod
   doesn't exist at all - no pod, no logs, only `journalctl -u kubelet` on cp1 (*could not process manifest file*).
   Indent with spaces (K10).
2. **kube-controller-manager**: `--kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig` - the file is
   `controller-manager.conf`. It crash-loops (*no such file or directory*); without it no ReplicaSets, no node
   lifecycle, no CSR signing (K04).
3. **k8s-w3's kubelet**: `server: https://k8s-api.lab:6444` in `kubelet.conf`; nothing listens there -> no lease
   renewals -> NotReady (L05).

**How to triage fast**: the API works, so start with `kubectl get pods -n kube-system -o wide` and `kubectl get nodes`;
then the node-level evidence (`crictl ps -a`, `crictl logs`, `journalctl -u kubelet`). Fix in dependency order:
scheduler and controller-manager first (cluster-wide), then the node.

**Interview notes**
- Static pods: the kubelet watches `/etc/kubernetes/manifests`; parse errors never reach the API.
- Hardening windows need a validation step (`kubeadm` dry-runs, `yamllint`, a canary node).
