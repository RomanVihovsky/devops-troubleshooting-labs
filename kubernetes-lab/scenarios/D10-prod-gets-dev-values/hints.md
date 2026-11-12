## Hint 1
`argocd app manifests web-prod | grep -E 'replicas|LOG_LEVEL'` - Argo CD renders exactly what you see. Which
files go into that render? `kubectl -n argocd get application web-prod -o jsonpath='{.spec.source.helm}'`.

## Hint 2
Helm merges `valueFiles` in order and **the last file wins**. What is listed last for prod?

## Hint 3
In `workspace/gitops/apps/web-prod.yaml`, prod's own file must come last (or the dev file goes away from the
list). Push, `argocd app get web-prod --refresh`.
