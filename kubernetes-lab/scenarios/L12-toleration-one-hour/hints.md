## Hint 1
`kubectl get nodes`; `kubectl -n checkout get pods -o wide`; `kubectl -n checkout get pod <pod on w2> -o
jsonpath='{.spec.tolerations}'`.

## Hint 2
When a node becomes unreachable, the node controller taints it `node.kubernetes.io/unreachable:NoExecute`.
Pods are evicted after their `tolerationSeconds` for that taint - the default is 300 s, admission adds it
unless the pod brings its own.

## Hint 3
Set both tolerations (`unreachable`, `not-ready`) to e.g. `tolerationSeconds: 60` in `api.yaml`, apply. The
rollout creates new pods on the healthy nodes; the old pod on k8s-w2 stays Terminating until the node
returns - that's fine for a Deployment.
