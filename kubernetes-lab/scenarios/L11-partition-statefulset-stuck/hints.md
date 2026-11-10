## Hint 1
`kubectl get nodes`, `kubectl -n inventory get pods -o wide`. Why would a Deployment replace its pods but a
StatefulSet not? Think about "at most one db-0".

## Hint 2
The API server marked db-0 for deletion, but only the kubelet on k8s-w3 can confirm the container is gone -
and it can't be reached. The StatefulSet controller waits for that confirmation forever.

## Hint 3
You know the node is dead (fenced): `kubectl -n inventory delete pod db-0 --force --grace-period=0`, or mark
the node with the non-graceful shutdown taint `node.kubernetes.io/out-of-service=nodeshutdown:NoExecute`.
The StatefulSet then creates db-0 elsewhere with the same PVC.
