# P13 - two reasons a pod stays Terminating

**Root cause**
1. **Grace period**: the app ignores SIGTERM (`SHUTDOWN_MODE=ignore`) and the pod has
   `terminationGracePeriodSeconds: 600`, so the kubelet waits 10 minutes before SIGKILL.
2. **Finalizer**: `example.com/cleanup` was put there by a "cleanup operator" that no longer exists. The API
   keeps an object with finalizers (deletionTimestamp set, "Terminating") until each finalizer is removed by
   its controller. Nobody will.

**Diagnosis**
```
kubectl -n queue get pod <old> -o jsonpath='{.metadata.deletionTimestamp} {.metadata.finalizers}'; echo
kubectl -n queue get pod <old> -o jsonpath='{.spec.terminationGracePeriodSeconds}'; echo
kubectl -n queue logs <old>                  # "SIGTERM received - ignoring (SHUTDOWN_MODE=ignore)"
```

**Fix**: remove the orphaned finalizer (`kubectl patch ... remove /metadata/finalizers`), force-delete if the
container is still in its grace period, and fix the Deployment (graceful SIGTERM handling, a realistic grace
period).

**Interview notes**
- Deletion = set `deletionTimestamp` → run finalizers (controllers remove theirs) → delete. "Terminating
  forever" = a finalizer whose controller is gone, or a node that can't confirm the pod stopped (L11).
- Removing a finalizer skips whatever cleanup it guarded. Do it on purpose (is the external resource
  gone?), not as a reflex.
- `--force --grace-period=0` removes the API object without waiting for the kubelet. The container may still
  run, which for StatefulSets risks two pods with the same identity.
- Graceful shutdown: handle SIGTERM, stop accepting, drain, exit, within the grace period (P16 covers the
  endpoints race).
