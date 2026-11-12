# W01 - a rollout that can neither finish nor fail

**Root cause**: 1.5 exits at start (missing `SESSION_SECRET`). With `maxUnavailable: 0` the Deployment keeps
all old pods and waits for the new one to become Ready, forever. `kubectl rollout status` reports failure only
when the Deployment's `Progressing` condition turns False, after `progressDeadlineSeconds` (3600 s here).

**Diagnosis**
```
kubectl -n storefront rollout status deploy/storefront --timeout=10s
kubectl -n storefront get rs -o wide            # new RS 1 desired / 0 ready, old RS 3/3
kubectl -n storefront logs <new pod> --previous # required setting SESSION_SECRET is not set
kubectl -n storefront get deploy storefront -o jsonpath='{.status.conditions}'
```

**Fix**: `kubectl rollout undo` (back to 1.4), and a realistic `progressDeadlineSeconds` (e.g. 300), so the next
bad release turns `Progressing=False / ProgressDeadlineExceeded` and `rollout status` exits non-zero.

**Interview notes**
- Deployments never roll back by themselves: the deadline only *reports* failure. Pipelines act on it
  (`rollout status` exit code, Argo Rollouts / Flagger analysis).
- `maxUnavailable: 0, maxSurge: 1` = zero-downtime and slow, and it protected users here. Compare with D03's
  `Recreate`, which turned a bad release into an outage.
- `rollout undo` uses the ReplicaSet history (`revisionHistoryLimit`, W11). With GitOps, revert in Git instead.
