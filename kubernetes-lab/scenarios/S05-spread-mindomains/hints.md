## Hint 1
`kubectl -n search describe pod <a pending pod>` and `kubectl -n search get deploy search-api -o yaml` - read
the whole `topologySpreadConstraints` entry, field by field.

## Hint 2
`minDomains: 3` tells the scheduler there should be at least 3 zones. While fewer domains exist, the global
minimum counts as **0**, so each zone may only hold `maxSkew` (1) pod - 2 zones, 2 pods.

## Hint 3
Drop `minDomains` (or set it to the number of zones that really exist, 2), keep `maxSkew: 1` on
`topology.kubernetes.io/zone`, and add `matchLabelKeys: [pod-template-hash]` - otherwise the new ReplicaSet's
pods are spread around the old ones during the rollout and can end up 3 + 1. Apply.
