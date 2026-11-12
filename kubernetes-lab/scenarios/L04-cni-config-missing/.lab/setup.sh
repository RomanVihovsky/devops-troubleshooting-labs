# L04: the CNI config is gone on k8s-w3
nx k8s-w3 'rm -rf /etc/cni/net.d/*' </dev/null
notready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 notready || die "k8s-w3 stayed Ready"
