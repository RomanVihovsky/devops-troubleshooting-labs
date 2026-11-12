nx k8s-w1 "sed -i 's|server: https://k8s-api.lab:6444|server: https://k8s-api.lab:6443|' /etc/kubernetes/kubelet.conf && systemctl restart kubelet" </dev/null
ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 120 ready || true
