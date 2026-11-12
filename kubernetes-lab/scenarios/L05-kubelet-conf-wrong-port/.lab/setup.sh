# L05: kubelet.conf points at port 6444 - nothing listens there
nx k8s-w1 "sed -i 's|server: https://k8s-api.lab:6443|server: https://k8s-api.lab:6444|' /etc/kubernetes/kubelet.conf && systemctl restart kubelet" </dev/null
notready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 notready || die "k8s-w1 stayed Ready"
