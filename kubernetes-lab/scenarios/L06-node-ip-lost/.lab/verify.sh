ip_ok() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)" = 192.168.56.32 ]; }
w2_ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
logs_ok() {
  local p; p=$(kx -n kube-system get pods -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w2 -o name 2>/dev/null | head -1)
  [ -n "$p" ] && kx -n kube-system logs "$p" -c calico-node --tail=1 >/dev/null
}
check_eventually 90 "k8s-w2 InternalIP 192.168.56.32" ip_ok
check_eventually 60 "k8s-w2 Ready" w2_ready
check_eventually 60 "kubectl logs works for a pod on k8s-w2" logs_ok
verdict
