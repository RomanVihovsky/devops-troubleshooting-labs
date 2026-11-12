# V07 - volume expansion is a StorageClass permission

**Root cause**: `nfs-standard` is a copy of `nfs` with `allowVolumeExpansion: false`. The API server's admission
refuses to raise `spec.resources.requests.storage` of a claim whose class doesn't allow expansion, with a
message that blames "dynamically provisioned" first.

**Diagnosis**
```
kubectl get storageclass -o custom-columns=NAME:.metadata.name,EXPAND:.allowVolumeExpansion,PROVISIONER:.provisioner
kubectl -n archive get pvc archive-data -o jsonpath='{.spec.storageClassName} {.status.capacity.storage}'; echo
```

**Fix**: `kubectl patch storageclass nfs-standard -p '{"allowVolumeExpansion": true}'`, re-apply the 2Gi
claim. The external-resizer calls the driver (ControllerExpandVolume) and updates the PV and the claim's
`status.capacity`. Some drivers then need a node-side resize: a remount or a pod restart (condition
`FileSystemResizePending`).

**Interview notes**
- Only growing is supported, never shrinking. `allowVolumeExpansion` is mutable, but most other
  StorageClass fields (provisioner, parameters, reclaimPolicy) are not: changing those means a new class.
- For NFS, "capacity" is bookkeeping (a quota at best). For block storage (EBS, Ceph RBD) the disk and the
  filesystem really grow, often online.
- StatefulSet `volumeClaimTemplates` can't be edited: patch each PVC, then recreate the StatefulSet with
  `--cascade=orphan` (V06).
