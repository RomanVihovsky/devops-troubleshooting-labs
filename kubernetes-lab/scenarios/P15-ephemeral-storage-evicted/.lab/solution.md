# P15 - ephemeral storage is a resource too

**Root cause**: the cache (300 MiB) went into the container's writable layer (`/tmp/cache` was no volume), and the
container's `ephemeral-storage` limit was 100Mi. The kubelet measures local storage per pod (writable layers +
logs + emptyDirs) and **evicts** pods that exceed their limits: status `Failed`, reason `Evicted`. The
ReplicaSet made new pods, which filled up and were evicted again.

**Diagnosis**
```
kubectl -n thumbs get pods                                   # Evicted / ContainerStatusUnknown
kubectl -n thumbs describe pod <evicted> | grep -A2 Message  # ephemeral local storage usage exceeds ...
kubectl -n thumbs get deploy thumbs -o jsonpath='{.spec.template.spec.containers[0].resources}'; echo
```

**Fix**: a volume sized for the cache, with limits that cover it: `emptyDir: {sizeLimit: 512Mi}` mounted at
`/tmp/cache` + `ephemeral-storage` limit 600Mi (emptyDir usage counts toward the pod's total), or a PVC (not
ephemeral, not counted).

**Interview notes**
- Requests for `ephemeral-storage` are scheduled like CPU/memory (`allocatable.ephemeral-storage`). Limits are
  enforced by **eviction**, not by a filesystem quota (unless the LocalStorageCapacityIsolationFSQuotaMonitoring
  feature is on).
- Writing data to the writable layer is slow (overlayfs copy-up) and goes away with the container. Big
  scratch data belongs on a volume.
- `emptyDir.medium: Memory` (tmpfs) counts toward **memory** instead, and can OOM-kill.
- Evicted pods stay as `Failed` objects until GC: `kubectl delete pods --field-selector=status.phase=Failed`.
