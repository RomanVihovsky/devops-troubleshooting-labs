# T05 - solution and takeaways

```
kubectl patch pv <pv of local-data> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
# shared.yaml: accessModes [ReadWriteMany], storageClassName nfs, and in the pod spec
topologySpreadConstraints:
  - {maxSkew: 1, topologyKey: kubernetes.io/hostname, whenUnsatisfiable: DoNotSchedule,
     labelSelector: {matchLabels: {app: writers}}}
# restore.yaml: VolumeSnapshot shared-snap (class nfs, source shared) + PVC restored with
#   dataSource: {apiGroup: snapshot.storage.k8s.io, kind: VolumeSnapshot, name: shared-snap}
```

**Takeaways**
- local-path = a directory on **one** node (`nodeAffinity` on the PV, `WaitForFirstConsumer` binding):
  fast and simple, but the pod is chained to that node. Node gone = pod Pending forever (L-domain
  incidents, StatefulSets on a dead node).
- RWX needs a shared filesystem (NFS, CephFS, ...). `ReadWriteOnce` means one **node**, not one pod;
  `ReadWriteOncePod` is the "one pod" mode.
- Reclaim policy lives on the PV: `Delete` (default from the StorageClass) removes the data with the claim,
  `Retain` keeps it - and leaves a `Released` PV someone has to clean up by hand.
- Snapshots are CSI-only (`VolumeSnapshotClass` + snapshot controller); csi-driver-nfs snapshots are
  tarballs on the NFS server. Restore = a new PVC with `dataSource`, never in place.
