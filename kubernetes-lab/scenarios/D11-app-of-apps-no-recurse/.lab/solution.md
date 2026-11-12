# D11 - app-of-apps reads only the top level

**Root cause**: the root Application `lab-apps` has a directory source `path: apps` without
`directory.recurse`. Argo CD's directory source reads only the files directly in `path`, so
`apps/team/metrics.yaml` was never part of the root app's manifests. The root app rightly said "Synced":
everything it knew of was in sync. The root app is bootstrapped by hand (`bootstrap/root.yaml`, applied once),
so no sync would ever change its own spec.

**Diagnosis**
```
argocd app manifests lab-apps | grep -c 'kind: Application'      # demo, shop - no metrics
kubectl -n argocd get application lab-apps -o jsonpath='{.spec.source}'; echo
git -C workspace/gitops ls-files apps
```

**Fix**: recurse into subdirectories, live and in the bootstrap file:
```
kubectl -n argocd patch application lab-apps --type merge -p '{"spec":{"source":{"directory":{"recurse":true}}}}'
# + the same `directory: {recurse: true}` in bootstrap/root.yaml, committed
```
(Moving the file to `apps/` also works, but the team wants `apps/<team>/`.)

**Interview notes**
- `directory` sources: `recurse`, `include`/`exclude` globs (e.g. `include: '{*.yaml,*/*.yaml}'`), `jsonnet`.
  Silent exclusion is the trap: nothing errors.
- Who manages the root? Either it is applied by hand (the bootstrap problem: changes need a manual apply, as
  here), or the root manages itself from Git (it lists its own manifest), or a cluster-bootstrap tool does it
  (Argo CD autopilot, Terraform, the Argo CD Helm chart's `extraObjects`).
- ApplicationSets (a Git directory generator, `apps/*/*`) scale this better than nested app-of-apps, and
  every team folder becomes an app automatically.
