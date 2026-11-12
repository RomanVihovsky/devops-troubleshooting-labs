nx k8s-w2 "swapoff -a && sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab && systemctl restart kubelet" </dev/null
ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 120 ready || true
