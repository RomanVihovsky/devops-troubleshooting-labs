# K05 - etcd's hostPath doesn't exist

**Root cause**: the migration updated `--data-dir` and the container's `mountPath` to `/var/lib/etcd-disk`, and changed
the `etcd-data` volume to `type: Directory` (a good idea: with kubeadm's default `DirectoryOrCreate` a wrong path would
silently create an **empty** directory - etcd would start a brand-new, empty cluster and every node would
re-register). But the hostPath says `/var/lib/etcd-disks`. The kubelet refuses the volume
(*hostPath type check failed: /var/lib/etcd-disks is not a directory*), the etcd pod never starts, and the API
server can't reach etcd.

**Diagnosis** (no API):
```
./lab node cp1
crictl ps -a | grep -E 'etcd|kube-apiserver'          # no etcd container; apiserver restarting
journalctl -u kubelet --since -10min | grep -i 'etcd' | tail
grep -n -A3 'etcd-data' /etc/kubernetes/manifests/etcd.yaml ; ls -d /var/lib/etcd*
```

**Fix**: correct the hostPath to `/var/lib/etcd-disk`, keep `type: Directory`. Edit a copy outside
`/etc/kubernetes/manifests/` and move it in (editors' backup files in that directory become extra static pods).

**Interview notes**
- Three places must agree: `--data-dir`, the `volumeMounts.mountPath`, and the `hostPath.path`.
- Data-dir moves: stop etcd (move the manifest out), copy with `cp -a` (ownership, permissions 0700), change all
  three, move the manifest back; check `etcdctl endpoint status` (same revision, same member ID).
- An etcd that comes up empty is worse than one that doesn't come up at all - `type: Directory` is the safety net.
