## Hint 1
`kubectl describe node k8s-w3`: conditions, taints and events (`EvictionThresholdMet`, `FreeDiskSpaceFailed`).
`kubectl get --raw /api/v1/nodes/k8s-w3/proxy/stats/summary | jq .node.fs`.

## Hint 2
`./lab node w3`, `sudo grep -A3 evictionHard /var/lib/kubelet/config.yaml`. `nodefs.available` is the share of
the disk that must stay **free**.

## Hint 3
Remove `evictionHard` (defaults: `nodefs.available<10%`, `imagefs.available<15%`, ...) or set `10%`, then
`sudo systemctl restart kubelet`. The taint goes away and the Pending pods schedule.
