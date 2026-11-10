# L11 - a StatefulSet pod on a dead node

**Root cause**: k8s-w3 is partitioned. After the eviction timeout the pods there are marked for deletion,
but a pod is only gone when its kubelet confirms it - impossible from an unreachable node. A Deployment
doesn't care (it creates replacements right away); a StatefulSet guarantees **at most one** `db-0`, so it
waits forever rather than risk two pods writing the same volume.

**Diagnosis**: `kubectl get nodes` (k8s-w3 NotReady/Unknown), `kubectl -n inventory get pods -o wide`
(db-0 Terminating on k8s-w3), `kubectl describe pod db-0` (deletionTimestamp, node unreachable taint).

**Fix** - only after making sure the node is really dead (fenced, powered off):
- `kubectl delete pod db-0 --force --grace-period=0`, or
- `kubectl taint node k8s-w3 node.kubernetes.io/out-of-service=nodeshutdown:NoExecute` (non-graceful node
  shutdown, GA 1.28: force-deletes its pods and detaches their volumes).

**Interview notes**
- "What happens to StatefulSet pods when a node goes NotReady?" - exactly this: they stay Terminating;
  Deployment pods are replaced after `tolerationSeconds` (300 s by default).
- Force-deleting while the node is alive = two writers on one volume (split brain). Fencing first.
- RWO on NFS isn't enforced by the storage; on block storage the VolumeAttachment would also need the
  out-of-service taint (or a 6-minute force-detach) before the new node can attach.
