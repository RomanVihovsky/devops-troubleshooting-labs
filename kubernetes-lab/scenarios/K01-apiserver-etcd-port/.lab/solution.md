# K01 - kube-apiserver can't reach etcd (wrong `--etcd-servers` port)

**Root cause**: the audit "harmonised" ports and changed `--etcd-servers=https://127.0.0.1:2379` to `:2397`
in `/etc/kubernetes/manifests/kube-apiserver.yaml`. kubelet recreated the static pod with the new flag; the
apiserver can't connect to etcd, never gets healthy and keeps restarting. haproxy on k8s-gw has no
healthy backend, so clients see `EOF`/refused.

**Diagnosis** (the API is down, so work on the node)
```
./lab node cp1
sudo crictl ps -a | grep -E 'kube-apiserver|etcd'          # apiserver Exited/restarting, etcd Running
sudo crictl logs $(sudo crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail
#   ... dial tcp 127.0.0.1:2397: connect: connection refused
sudo grep -- --etcd-servers /etc/kubernetes/manifests/kube-apiserver.yaml
sudo grep -- --listen-client-urls /etc/kubernetes/manifests/etcd.yaml   # :2379
```

**Fix**: put `:2379` back in the manifest; kubelet notices within seconds and recreates the pod.

**Interview notes**
- Static pods: kubelet watches `staticPodPath` (`/etc/kubernetes/manifests`); the API only shows mirror
  pods. With the API down, `crictl` and `journalctl -u kubelet` are your tools.
- Never keep backups *in* `manifests/` - kubelet runs every file there (two apiservers on one port).
- `kubeadm` keeps the source of truth in the `kubeadm-config` ConfigMap; `kubeadm upgrade` regenerates the
  manifests from it, so hand edits must also go there (ClusterConfiguration) to survive an upgrade.
