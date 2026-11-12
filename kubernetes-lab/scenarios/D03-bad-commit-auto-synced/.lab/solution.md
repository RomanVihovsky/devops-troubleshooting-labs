# D03 - roll back with a Git revert

**Root cause**: the RC `2.0.0-rc1` exits at start ("required setting FEATURE_FLAGS_URL is not set"), and the
commit also switched to `strategy: Recreate` - every old pod was stopped first. Auto-sync did its job: it
deployed `main`.

**Diagnosis**
```
argocd app get demo                       # Synced, Degraded/Progressing
kubectl -n demo logs <pod> --previous     # required setting FEATURE_FLAGS_URL is not set
git -C workspace/gitops log --oneline -5
```

**Fix**: `git revert <rc commit>` and push. Argo CD syncs the revert; demo comes back.

**Interview notes**
- In GitOps, Git is the rollback mechanism. `kubectl rollout undo` fights self-heal; `argocd app rollback`
  requires disabling auto-sync and leaves Git saying something else - both are drift.
- Revert, don't force-push: the audit trail stays, collaborators' clones stay valid, and re-applying the RC
  is a revert of the revert.
- `Recreate` turns a bad release into an outage; `RollingUpdate` (+ readiness probes) would have kept the old
  pods serving. Argo CD sync waves / PreSync hooks or Argo Rollouts (canary, analysis) catch this earlier.
