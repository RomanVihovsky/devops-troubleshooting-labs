# Can't drain k8s-w1 for its kernel update
**CHG-9031** · P3 · Reporter: platform team

`kubectl drain k8s-w1 --ignore-daemonsets --delete-emptydir-data` retries forever: *Cannot evict pod as it would
violate the pod's disruption budget* (`ha/ha-api`). I gave up; `k8s-w1` is cordoned now. `ha-api` (3 replicas)
must stay available during maintenance - at least 2 serving at all times - but maintenance must be possible.
Drain `k8s-w1`, then return it to service (the kernel update is done by then).

**Test**: the `ha-api` pod that ran on `k8s-w1` was evicted (drain done), `k8s-w1` is schedulable again, `ha-api`
has 3 Ready pods, and its PodDisruptionBudget still exists and still guarantees 2 available pods.
