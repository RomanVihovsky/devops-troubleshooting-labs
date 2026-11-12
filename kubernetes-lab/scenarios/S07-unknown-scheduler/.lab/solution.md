# S07 - waiting for a scheduler that doesn't exist

**Root cause**: `schedulerName: gpu-scheduler` (from another cluster). Each scheduler only picks up pods
with its own name; nobody here is called gpu-scheduler, so nobody ever looks at the pod - no
FailedScheduling event either.

**Fix**: drop `schedulerName` (defaults to `default-scheduler`).

**Interview notes**
- Pending + no events: scheduler down (K03) or a foreign `schedulerName`. Pending + FailedScheduling: the
  scheduler ran and explained.
- Multiple schedulers / scheduler profiles are legitimate (batch schedulers like Volcano/Kueue, GPU
  binpacking) - the name must exist.
