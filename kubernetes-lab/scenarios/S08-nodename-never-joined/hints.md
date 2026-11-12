## Hint 1
`kubectl get nodes` - is k8s-w4 there? `kubectl -n legacy get pod <pod> -o jsonpath='{.spec.nodeName}'`.

## Hint 2
`spec.nodeName` bypasses the scheduler completely: the pod is "bound" to that node, and only that node's
kubelet would ever start it.

## Hint 3
Remove `nodeName` (use a nodeSelector if you need placement), apply.
