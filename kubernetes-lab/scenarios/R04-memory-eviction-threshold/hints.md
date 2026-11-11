## Hint 1
`kubectl describe node k8s-w2` (Conditions, Taints, events) and
`kubectl get --raw /api/v1/nodes/k8s-w2/proxy/stats/summary | jq .node.memory.availableBytes`. What does the
kubelet compare that number with?

## Hint 2
`./lab node w2`, `sudo grep -A3 evictionHard /var/lib/kubelet/config.yaml`. A threshold above what the node has
free means permanent pressure. The kubelet evicts BestEffort pods first, then Burstable pods by how far they
exceed their requests; Guaranteed pods last.

## Hint 3
Remove `evictionHard` (defaults: memory.available 100Mi) or set something like `200Mi`, `sudo systemctl restart
kubelet`. Then `kubectl -n payments set resources deploy/payments-api --requests=cpu=100m,memory=256Mi
--limits=cpu=100m,memory=256Mi` (requests = limits for every container → Guaranteed).
