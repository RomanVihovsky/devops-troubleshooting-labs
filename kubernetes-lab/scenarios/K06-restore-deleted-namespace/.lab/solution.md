# K06 - restoring a namespace from an etcd snapshot

**Root cause**: `kubectl delete ns prod` deleted every object in it. Nothing reconciles `prod` from Git, so the only
copy is the etcd snapshot taken just before.

**Fix** (on `k8s-cp1`; a single-member etcd):
```
etcdutl snapshot status /var/backups/etcd/etcd-nightly.db -w table
etcdutl snapshot restore /var/backups/etcd/etcd-nightly.db --data-dir /var/lib/etcd-restored \
  --name k8s-cp1 --initial-cluster k8s-cp1=https://<ip>:2380 --initial-advertise-peer-urls https://<ip>:2380
sed -i 's|path: /var/lib/etcd$|path: /var/lib/etcd-restored|' /etc/kubernetes/manifests/etcd.yaml   # the etcd-data hostPath
crictl stop $(crictl ps --name kube-apiserver -q)        # drop the API server's watch cache of the old data
```
The whole cluster goes back to the snapshot's moment: objects created since are lost, deleted ones return with their
**original UIDs** (owner references and finalizers keep working). Kubelets and controllers reconcile the rest -
`orders`' pods come back as new pods.

**Kubelets after a restore**: their watches point at revisions newer than the restored store and stall - restart
the kubelet on every node, or new pods are never started.

**Ghost pods**: the snapshot brings back the old Pod objects with status *Running*, but their kubelets already
terminated those UIDs and won't start them again (`exec`: *pod does not exist*). Recreate them:
`kubectl -n prod delete pod --all --grace-period=0 --force` (a graceful delete would hang in *Terminating*: no kubelet
confirms it) - the ReplicaSet makes real ones.

**Interview notes**
- Restoring = going back in time for **everything**: prefer re-applying from Git/Velero for a single namespace when
  you can; etcd restore is the last resort (or the DR path).
- Multi-member clusters: restore every member from the **same** snapshot with a new `--initial-cluster-token`, stop
  all API servers first.
- `etcdctl snapshot save` needs the client certs (`/etc/kubernetes/pki/etcd/`); keep snapshots off the node.
- Leaving a backup copy of a manifest in `/etc/kubernetes/manifests/` starts a second static pod.
