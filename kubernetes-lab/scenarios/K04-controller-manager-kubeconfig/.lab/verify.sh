kcm_ready() { [ "$(kx -n kube-system get pod "kube-controller-manager-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
kubeconfig_exists() {
  local f; f=$(nx "$CP" "grep -o -- '--kubeconfig=[^ ]*' /etc/kubernetes/manifests/kube-controller-manager.yaml | cut -d= -f2" </dev/null)
  [ -n "$f" ] && nx "$CP" "test -s $f" </dev/null
}
web_ready() { [ "$(kx -n ops get deploy web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 2 ]; }
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check_eventually 180 "kube-controller-manager Ready" kcm_ready
check "its --kubeconfig exists" kubeconfig_exists
check_eventually 120 "ops/web: 2 ready replicas" web_ready
check "only the 4 control-plane manifests" manifests4
verdict
