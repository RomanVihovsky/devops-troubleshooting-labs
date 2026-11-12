# T08 - solution and takeaways

```
etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/backups/etcd-t08.db
etcdutl snapshot status /var/backups/etcd-t08.db -w table
kubectl delete namespace t08                                    # the accident
etcdutl snapshot restore /var/backups/etcd-t08.db --data-dir /var/lib/etcd-t08 --name k8s-cp1 \
  --initial-cluster k8s-cp1=https://192.168.56.21:2380 --initial-advertise-peer-urls https://192.168.56.21:2380
# etcd.yaml: volumes -> etcd-data -> hostPath.path: /var/lib/etcd-t08
crictl stop $(crictl ps --name kube-apiserver -q)               # no stale watch cache
```

**Takeaways**
- An etcd snapshot is the complete API state: every object, Secret, CRD, RBAC rule, lease. It is *not*
  the PKI (`/etc/kubernetes/pki`), the static pod manifests or any PersistentVolume data: back those up
  separately.
- `snapshot save` uses `etcdctl` against a live member; `snapshot restore` / `status` are offline
  `etcdutl` work (etcdctl's versions are deprecated). A restore creates a **new** cluster (new cluster ID):
  all members of a multi-node etcd must be restored from the same snapshot.
- Restoring rewinds everything: objects created after the snapshot vanish, controllers reconcile towards
  the old state, revision numbers jump back - restart the API servers (and anything with a watch cache).
- The snapshot holds Secrets in plain text unless encryption at rest is on (T16): protect the file.
- This lab's own `./lab cluster reset` is exactly this drill, scripted, with a golden snapshot.
