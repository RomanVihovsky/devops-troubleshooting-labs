# B06 - disaster recovery in the right order

**Two independent failures**:
1. The API server's serving certificate was renewed with `certificateValidityPeriod: 3m0s` and expired - every client
   gets *x509: certificate has expired*. Renew it with the normal lifetime from the local config, restart the API
   server: `kubeadm certs renew apiserver --config /etc/kubernetes/kubeadm/init.yaml`.
2. `prod` was deleted after the backup. Restore the etcd snapshot (K06): `etcdutl snapshot restore` into a new data dir,
   point the `etcd-data` hostPath at it; the API server restarts with the restored state.

**The data**: the PVC came back from the snapshot with its original UID, bound to its PV. The class `nfs-retain` never
deleted the NFS directory when the PVC was deleted, so ledger's `balance` is exactly what it was. With a `Delete`
class the restore would have brought back an empty, re-provisioned volume - or a PV pointing at nothing.

**Kubelets after a restore**: the store's revision is now older than what every kubelet last watched; their
watches stall and new pods on their nodes never start. Restart the kubelet on every node and the node agents that watch the API - calico-node (otherwise new pods get no
network: readiness probes time out) and kube-proxy: `kubectl -n kube-system rollout restart ds/calico-node
ds/kube-proxy` (the etcd restore docs: restart everything that might rely on stale data).

**Ghost pods**: the snapshot also brings back the old **Pod** objects, status *Running* - but their kubelets
terminated those UIDs when the namespace was deleted and won't start them again; `exec` says *pod does not exist*.
Recreate them: `kubectl -n prod delete pod --all --grace-period=0 --force` - no kubelet will ever confirm a graceful
deletion of a ghost, it would hang in *Terminating*.

**Order**: access first (certs), then state (etcd), then recreate the workloads and verify their data.

**Interview notes**
- An etcd snapshot contains objects, not volume data - DR needs volume backups or `Retain` + a known mapping.
- Restoring etcd rewinds everything: Leases, endpoints, ReplicaSets - controllers and kubelets reconcile, but
  anything created after the snapshot is gone.
- Practise DR before you need it (and keep the snapshot and the PKI off the node).
