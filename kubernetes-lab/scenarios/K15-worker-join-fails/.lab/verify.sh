w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
w3_ip() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)" = 192.168.56.33 ]; }
w3_zone() { [ "$(kx get node k8s-w3 -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' 2>/dev/null)" = zone-b ]; }
w3_logs() {
  local p; p=$(kx -n kube-system get pods -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w3 -o name 2>/dev/null | head -1)
  [ -n "$p" ] && kx -n kube-system logs "$p" -c calico-node --tail=1 >/dev/null
}
kubelet_enabled() { [ "$(nx k8s-w3 'systemctl is-enabled kubelet' </dev/null)" = enabled ]; }
no_forever() { ! nx "$CP" 'kubeadm token list 2>/dev/null' </dev/null | awk 'NR > 1 { print $2 }' | grep -q '<forever>'; }
check_eventually 120 "k8s-w3 registered and Ready" w3_ready
check "k8s-w3 InternalIP 192.168.56.33" w3_ip
check "k8s-w3 in zone-b" w3_zone
check_eventually 60 "kubectl logs works for a pod on k8s-w3 (serving cert approved)" w3_logs
check "kubelet enabled on k8s-w3" kubelet_enabled
check "no join token without expiry" no_forever
verdict
