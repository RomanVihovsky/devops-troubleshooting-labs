# D05 - Argo CD's repository credentials after a rotation

**Root cause**: the Gitea account `argocd` got a new password, but Argo CD's repository Secret
`argocd/repo-gitops` (label `argocd.argoproj.io/secret-type: repository`) still held the old one. Every fetch
failed with *authentication required*. With nothing to compare, every app's sync status turned *Unknown*.

**Diagnosis**
```
argocd app get demo                  # ComparisonError: ... repository not accessible: authentication required
kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository
argocd repo list                     # CONNECTION STATUS Failed
bao kv get -mount=secret ci/gitea-argocd
```

**Fix**: put the new password into the repository Secret, then hard-refresh the apps:
```
kubectl -n argocd patch secret repo-gitops --type merge -p '{"stringData":{"password":"<new>"}}'
argocd app get demo --hard-refresh
```

**Interview notes**
- Argo CD reads repository credentials from Secrets labelled `secret-type: repository` (one URL) or
  `repo-creds` (a credential template for a URL prefix: every repo of an org). `argocd repo add` writes the
  same kind of Secret.
- Apps keep running while Argo CD can't fetch. Only *new* changes stop, so a broken credential can go unnoticed
  for days. Alert on `argocd_app_info{sync_status="Unknown"}` or on the repo connection state.
- Better than a password: a read-only deploy key or a scoped token, rotated by automation. For example, ESO
  can write the repo Secret from the vault, so a rotation reaches Argo CD by itself.
- Don't "fix" it with an admin's token. Argo CD only needs read access, and an admin token in a cluster
  Secret gives everyone who can read Secrets in `argocd` write access to every repo.
