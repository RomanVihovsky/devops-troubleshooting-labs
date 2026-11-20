## Hint 1
Who turns a ClusterIP into a pod IP on a node? `kubectl -n kube-system get pods -o wide -l k8s-app=kube-proxy` -
count them per node.

## Hint 2
`kubectl -n kube-system get ds kube-proxy -o yaml` - look at `affinity`. Without kube-proxy on w2, the iptables rules
it wrote earlier stay - old Services work - but nothing new is ever programmed there
(`./lab node w2`, `iptables-save | grep -c pricing`).

## Hint 3
Remove the node affinity that excludes `k8s-w2` (`kubectl -n kube-system edit ds kube-proxy`); the new kube-proxy pod
syncs all rules within seconds.
