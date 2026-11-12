## Hint 1
`kubectl -n ring get svc peers` - which IP does the name resolve to? `nslookup peers.ring` from a pod.

## Hint 2
A normal Service has one virtual IP (ClusterIP), load-balanced by kube-proxy. A **headless** Service
(`clusterIP: None`) makes DNS return the ready pod IPs directly.

## Hint 3
`spec.clusterIP` is immutable: delete the Service and apply it again with `clusterIP: None`.
