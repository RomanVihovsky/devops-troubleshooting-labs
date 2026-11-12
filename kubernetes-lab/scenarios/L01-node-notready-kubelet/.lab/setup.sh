# L01: kubelet stopped and disabled on k8s-w2 (the "patch runbook" without the reboot)
nx k8s-w2 'systemctl disable --now kubelet 2>/dev/null' </dev/null
w2_notready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 w2_notready || die "k8s-w2 did not go NotReady"
