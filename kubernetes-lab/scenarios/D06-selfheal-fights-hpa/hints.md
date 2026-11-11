## Hint 1
`argocd app get demo` and `argocd app history demo`: what does Argo CD keep changing back? Compare
`kubectl -n demo get deploy demo -o jsonpath='{.spec.replicas}'` with what the chart renders and what the HPA
wants (`kubectl -n demo get hpa demo`).

## Hint 2
Two controllers own the same field: the chart renders `replicas: 2`, the HPA sets 3, and self-heal reverts
the HPA. Either Git stops rendering `replicas` (the chart drops it when `autoscaling.enabled`), or the
Application ignores `/spec/replicas` - then it also needs the sync option `RespectIgnoreDifferences=true`.

## Hint 3
In `workspace/gitops/envs/demo/values.yaml`:
`autoscaling: {enabled: true, minReplicas: 3, maxReplicas: 6}` - the chart then renders the HPA itself and no
`replicas`. Commit, push, `argocd app get demo --refresh`.
