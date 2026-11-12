# W11 - rollout history is ReplicaSets

**Root cause**: `rollout undo` doesn't store manifests anywhere. The "history" is the old ReplicaSets, scaled to 0
and kept up to `revisionHistoryLimit`. With `0`, the controller deletes the old ReplicaSet as soon as a rollout
**completes**. The bad release completed: its pods passed readiness (the app starts fine) and fail at runtime,
since every `/items` call hits the broken pricing integration. So the 1.3 ReplicaSet vanished, and `undo` had
nothing to go back to.

**Diagnosis**
```
kubectl -n pay rollout history deploy/checkout       # only the current revision
kubectl -n pay get rs                                # one ReplicaSet
kubectl -n pay get deploy checkout -o jsonpath='{.spec.revisionHistoryLimit}'; echo
kubectl -n pay exec deploy/checkout -- labapp get http://localhost:8080/items   # 500
```

**Fix**: roll **forward** to the known good spec (image 1.3, no `ERROR_RATE`), from the release notes or Git, and
restore a history limit (default 10).

**Interview notes**
- Each revision = a ReplicaSet with annotation `deployment.kubernetes.io/revision`. `rollout undo
  --to-revision=N` scales that ReplicaSet back up. Old ReplicaSets are pruned only when a rollout completes, so
  a release that crash-loops keeps its predecessor; one that is Ready but wrong doesn't.
- Readiness that only checks "the process is up" lets a broken release complete. Check a real dependency or
  path, or gate the rollout on metrics (Argo Rollouts / Flagger analysis).
- Lowering `revisionHistoryLimit` to save etcd space is rarely worth it. GitOps users often keep it low
  because Git is the history. Then the rollback path is a revert (D03), and the on-call needs to know that.
