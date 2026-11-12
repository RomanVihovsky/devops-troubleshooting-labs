## Hint 1
`kubectl top nodes`, then `kubectl top pods -A --sort-by=cpu` (metrics-server, 15 s resolution).

## Hint 2
Only pods on `k8s-w1`: `kubectl get pods -A -o wide --field-selector spec.nodeName=k8s-w1`. On the node itself:
`./lab node w1`, `sudo crictl stats` (per container).

## Hint 3
Write the pod name (as `kubectl get pods` shows it) or its Deployment into `answers.yaml` under `pod:`.
