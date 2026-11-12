## Hint 1
`kubectl -n thumbs describe pod <pending pod>`; `kubectl get pv <the PV> -o jsonpath='{.spec.nodeAffinity}'`.

## Hint 2
One PVC shared by both replicas: a local-path volume lives on one node, but the anti-affinity forbids two
pods there. "Each with its own volume" is what a StatefulSet's `volumeClaimTemplates` gives you.

## Hint 3
Turn `thumbs` into a StatefulSet (`serviceName`, `volumeClaimTemplates` with local-path) and delete the
Deployment + the shared PVC.
