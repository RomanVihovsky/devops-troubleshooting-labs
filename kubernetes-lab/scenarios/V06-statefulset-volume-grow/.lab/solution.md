# V06 - volumeClaimTemplates are immutable; PVCs are not

**Root cause**: a StatefulSet's `volumeClaimTemplates` can't be changed after creation (the API rejects it: only
replicas, template, updateStrategy, ... may change). The template is only a **recipe** used when a PVC doesn't
exist yet; the running replicas' disks are ordinary PVCs (`data-tsdb-0`, `data-tsdb-1`).

**Diagnosis**
```
kubectl -n metrics apply -f tsdb.yaml          # Forbidden: updates to statefulset spec for fields other than ...
kubectl -n metrics get pvc                      # the real disks
kubectl get sc nfs -o jsonpath='{.allowVolumeExpansion}'
```

**Fix** (no data movement):
1. expand each PVC: `kubectl -n metrics patch pvc data-tsdb-0 -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'`
   (and `-1`); watch `status.capacity` follow;
2. update the recipe for future replicas: `kubectl -n metrics delete sts tsdb --cascade=orphan` (pods and PVCs
   keep running), then `kubectl apply -f tsdb.yaml` with 2Gi - the new StatefulSet adopts the orphans by label.

**Interview notes**
- Expansion needs `allowVolumeExpansion: true` and a driver that supports it; shrinking is never allowed.
- Block storage may need a pod restart for the filesystem resize (`FileSystemResizePending` condition); NFS
  doesn't.
- Newer Kubernetes versions add in-place StatefulSet volume template updates behind a feature gate - check
  before relying on it.
- `--cascade=orphan` is also how you change a StatefulSet's `serviceName` or selector-adjacent fields.
