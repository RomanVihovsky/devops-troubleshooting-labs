# D10 - Helm valueFiles: the last one wins

**Root cause**: the "shared defaults" cleanup made `web-prod` render
`valueFiles: [envs/web-prod/values.yaml, envs/web-dev/values.yaml]`. Helm merges values files left to right,
and later files override earlier ones key by key. Every key that dev sets (`replicaCount: 1`,
`app.logLevel: debug`) won. Prod's file was right, but it was overridden.

**Diagnosis**
```
argocd app manifests web-prod | grep -E 'replicas:|LOG_LEVEL'
kubectl -n argocd get application web-prod -o jsonpath='{.spec.source.helm.valueFiles}'; echo
helm template web charts/labapp -f envs/web-prod/values.yaml -f envs/web-dev/values.yaml | grep replicas   # reproduce locally
```

**Fix**: prod lists only its own file (or shared defaults first, the environment's file last):
`valueFiles: [../../envs/common/values.yaml, ../../envs/web-prod/values.yaml]`.

**Interview notes**
- Precedence, lowest to highest: the chart's `values.yaml` < `valueFiles` (in order) < `values`/`valuesObject` <
  `parameters` (`--set`). The same order applies to `helm -f a -f b --set`.
- Maps merge deeply, but **lists are replaced whole**: a `tolerations:` in a later file replaces the earlier
  list. Deleting a key needs `null`.
- Catch it before it ships: render every environment in CI (`helm template` / `argocd app diff`) and review
  the rendered diff, not just the values diff.
- Kustomize overlays have their own version of this pitfall: a patch that targets the wrong name (O08).
