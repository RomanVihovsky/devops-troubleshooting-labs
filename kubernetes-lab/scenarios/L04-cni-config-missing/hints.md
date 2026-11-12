## Hint 1
`ls /etc/cni/net.d` on k8s-w3, then compare with k8s-w1. Who put those files there in the first place?

## Hint 2
The CNI plugin (Calico) installs its config and binaries from an init container of its DaemonSet pod
(`calico-node`, init container `install-cni`) - at pod start.

## Hint 3
`kubectl -n kube-system delete pod -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w3`: the new
calico-node pod reinstalls the CNI config, the kubelet sees it, the node turns Ready.
