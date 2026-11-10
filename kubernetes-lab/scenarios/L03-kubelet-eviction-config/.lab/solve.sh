nx k8s-w2 "sed -i 's/memory.available: 200MB/memory.available: 200Mi/' /var/lib/kubelet/config.yaml && systemctl restart kubelet" </dev/null
ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 120 ready || true
