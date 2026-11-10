## Hint 1
`kubectl describe node k8s-w1 | grep -A3 Taints`; `kubectl -n etl describe pod <pod>`.

## Hint 2
A taint repels every pod that doesn't explicitly tolerate it: key, value and effect must match the
toleration.

## Hint 3
`tolerations: [{key: dedicated, operator: Equal, value: batch, effect: NoSchedule}]` in the pod template,
apply.
