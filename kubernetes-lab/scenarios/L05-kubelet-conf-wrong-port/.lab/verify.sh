w1_ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
server_ok() { [ "$(nx k8s-w1 "awk '/server:/ { print \$2 }' /etc/kubernetes/kubelet.conf" </dev/null)" = https://k8s-api.lab:6443 ]; }
check_eventually 120 "k8s-w1 Ready" w1_ready
check "kubelet.conf server: https://k8s-api.lab:6443" server_ok
verdict
