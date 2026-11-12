## Hint 1
`kubectl -n logging get ds log-agent` (DESIRED) and `kubectl describe node k8s-w1 | grep Taints`.

## Hint 2
DaemonSet pods respect taints like other pods (only the `node.kubernetes.io/*` ones are tolerated
automatically). `NoExecute` also evicts running pods that don't tolerate it.

## Hint 3
Add a toleration to the pod template: `tolerations: [{key: maintenance, operator: Exists, effect: NoExecute}]`,
apply.
