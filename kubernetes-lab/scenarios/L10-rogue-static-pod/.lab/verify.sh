no_pod_for() {
  local t=$1; [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3
  kx get pods -A --no-headers 2>/dev/null | grep -q 'netdebug-' && return 1
  sleep "$t"; ! kx get pods -A --no-headers 2>/dev/null | grep -q 'netdebug-'
}
no_container() { ! nx k8s-w2 'crictl ps -a --name debug -q | grep -q .' </dev/null; }
static_path() { nx k8s-w2 'grep -qx "staticPodPath: /etc/kubernetes/manifests" /var/lib/kubelet/config.yaml' </dev/null; }
w2_ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
check_eventually 120 "no netdebug pod for 60 s" no_pod_for 60
check "no netdebug container left on k8s-w2" no_container
check "kubelet on k8s-w2 still reads static pods from /etc/kubernetes/manifests" static_path
check_eventually 60 "k8s-w2 Ready" w2_ready
verdict
