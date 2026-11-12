# O08 - a Kustomize patch that matches nothing

**Root cause**: the prod overlay's JSON patch has `target: {kind: Deployment, name: webapp}`. The base's Deployment
is `web`. A target selector that matches nothing is not an error in Kustomize: the patch is skipped, and the
overlay renders the base unchanged (1 replica, debug).

**Diagnosis**
```
kubectl kustomize workspace/O08/overlays/prod | grep -E 'name:|replicas|value:'
grep -A2 target workspace/O08/overlays/prod/kustomization.yaml
```

**Fix**: `target: {kind: Deployment, name: web}`, re-apply.

**Interview notes**
- Strategic-merge patches identify their target by the patch's own `kind/name`, and a missing target **is**
  an error there ("no matches for Id"). Targeted (`target:`) and JSON 6902 patches with selectors fail
  silently.
- Review the **rendered** diff per environment in CI (`kubectl diff -k`, `kustomize build | kubeconform`), not
  only the overlay files. The same lesson as D10 for Helm.
