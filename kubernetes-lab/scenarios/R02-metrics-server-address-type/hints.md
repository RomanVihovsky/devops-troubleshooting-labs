## Hint 1
`kubectl -n kube-system logs deploy/metrics-server --tail=20` - which address does it dial for each node?
`kubectl get apiservice v1beta1.metrics.k8s.io` tells you whether the API server can reach metrics-server.

## Hint 2
`--kubelet-preferred-address-types` picks which Node address metrics-server uses. Node *hostnames* only resolve
where something knows them - the pods' DNS (CoreDNS) doesn't.

## Hint 3
`kubectl -n kube-system edit deploy metrics-server`: `--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname`.
The kubelets' serving certificates contain their IPs, so TLS verification keeps working.
