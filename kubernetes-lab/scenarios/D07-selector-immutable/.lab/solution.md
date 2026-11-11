# D07 - an immutable selector in a shared chart

**Root cause**: the chart change put `app.kubernetes.io/version` into `labapp.selectorLabels`, which the
Deployment selector, the Service selector and the PDB all use. `apps/v1` Deployments can't change
`spec.selector`, so every sync failed at the Deployments, and nothing new could be released. The Services had
already been applied (their selector is mutable) and now select `version: "1.4"`. The running pods still
match, by luck; the next version bump would have emptied the Service's endpoints in the middle of a rollout.

**Diagnosis**
```
argocd app get demo                       # SyncFailed: Deployment.apps "demo" is invalid: spec.selector: ... field is immutable
kubectl -n demo get svc demo -o jsonpath='{.spec.selector}'; echo     # already has version
kubectl -n demo get deploy demo -o jsonpath='{.spec.selector}'; echo  # unchanged
git -C workspace/gitops log -p -1 -- charts/labapp
```

**Fix**: `git revert` the chart commit and push. demo and shop sync again, and the Services go back to the
stable selector.

**Interview notes**
- Selector labels must be **stable for the life of the object**: name + instance. Versions, hashes and
  `helm.sh/chart` belong on the pod template and metadata, never in a selector.
- `Replace=true` / `--force` or deleting the Deployment does "work", but with downtime and lost rollout
  history, in every app at once. Changing a selector really means a new Deployment (new name) next to the old
  one, a cutover, then deleting the old one.
- Routing per version is a job for a second Service or a Gateway HTTPRoute with weighted backendRefs, or for
  Argo Rollouts. It does not belong in the main Service's selector.
- A shared chart is a blast radius: version it, render it in CI against every app's values, and roll it out
  app by app.
