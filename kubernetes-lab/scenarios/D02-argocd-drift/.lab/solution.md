# D02 - drift while self-heal is off

**Root cause**: the change freeze set `selfHeal: false`. Argo CD's automated sync then only applies **Git
changes**; live edits (`kubectl scale`, `kubectl set env`) stay until someone syncs. The app shows
*OutOfSync* - correctly - and nobody reacted.

There is a second, quieter layer. The replica count is a field Git declares, so Argo CD sees the drift and a
sync puts it back. The `GREETING` env var was **never in Git**. Argo CD diffs (and syncs) with a three-way
merge against the last-applied config, so a field nobody declared is not drift: after the sync the app is
*Synced* and Healthy, and the hotfix is still running.

**Diagnosis**
```
argocd app get demo; argocd app diff demo          # replicas 5 vs 2 - and no word about GREETING
kubectl -n argocd get app demo -o jsonpath='{.spec.syncPolicy}'
git -C workspace/gitops log --oneline -3            # the freeze commit
kubectl -n demo get deploy demo -o jsonpath='{.spec.template.spec.containers[0].env[*].name}'   # GREETING
```

**Fix**: Git is right and the freeze stays, so sync from Git: `argocd app sync demo` (or *Sync* in the UI).
Then remove what Git never declared: `kubectl -n demo set env deploy/demo GREETING-`. Alternatively, a sync
with the **Replace** option (`argocd app sync demo --replace`) replaces the object as a whole. Don't "fix" anything by turning self-heal back on - that
breaks the freeze - and don't rewrite Git history.

**Interview notes**
- `automated` = sync on Git changes; `selfHeal` = also revert live drift; `prune` = delete what's no longer
  in Git. Three independent switches.
- Drift detection compares the rendered manifests with live state using the last-applied config (or field
  managers with server-side apply): fields nobody declared - an extra env var, label or annotation added by
  hand - are not drift, and neither self-heal nor a sync removes them. "Synced" means "everything Git
  declares matches", not "the object is exactly what Git renders".
- In GitOps the durable fix is a commit (or a revert); `kubectl edit` in production is a temporary
  workaround at best, and only the declared parts of it get reverted by the next sync.
