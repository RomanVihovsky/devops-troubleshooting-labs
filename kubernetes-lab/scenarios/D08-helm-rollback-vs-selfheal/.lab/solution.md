# D08 - helm rollback against an Argo CD-managed app

**Root cause**: ledger was installed with `helm install`, then adopted by an Argo CD Application with the same
release name. From that moment Argo CD owned it: it renders the chart with `helm template` and applies the
result, and it never touches Helm's release records. The bad 1.5 came from a Git commit. `helm rollback`
re-applied revision 1 (the 1.4 install) to the cluster. To Argo CD that was drift, and self-heal synced Git
(1.5) back a minute later. The Helm records (`sh.helm.release.v1.ledger.v1/v2`) were stale leftovers that made
`helm history` look authoritative.

**Diagnosis**
```
argocd app history ledger                 # the 1.5 sync, then a self-heal sync after the rollback
helm history ledger -n ledger              # revisions that Argo CD never wrote
kubectl -n ledger logs deploy/ledger       # required setting SESSION_SECRET is not set
git -C workspace/gitops log --oneline -- envs/ledger
```

**Fix**
```
git -C workspace/gitops revert --no-edit <the 1.5 commit> && git -C workspace/gitops push
argocd app get ledger --refresh
kubectl -n ledger delete secret -l owner=helm,name=ledger    # nobody "helm rollback"s this app again
```

**Interview notes**
- With Argo CD, Helm is a templating engine, not a release manager. No `helm list`, no hooks bookkeeping in
  release Secrets, no `helm rollback`. Rollback = `git revert`. `argocd app rollback` needs auto-sync off and
  leaves Git saying something else.
- Adopting a Helm release: keep the same release name (the same `app.kubernetes.io/instance`) so the objects
  match, then delete the release Secrets. Otherwise someone will trust them during an incident.
- `--force-conflicts` was a warning sign. Server-side apply reported that another manager owned those
  fields.
- Runbooks age: update them when an app moves to GitOps.
