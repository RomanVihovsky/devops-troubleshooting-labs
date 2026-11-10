active() { [ "$(nx k8s-w2 'systemctl is-active kubelet' </dev/null)" = active ]; }
w2_ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
tuning() {
  nx k8s-w2 'cat /var/lib/kubelet/config.yaml' </dev/null | python3 -c 'import sys, yaml
e = (yaml.safe_load(sys.stdin) or {}).get("evictionHard") or {}
sys.exit(0 if str(e.get("memory.available")) in ("200Mi", "200M") and str(e.get("nodefs.available")) == "10%" else 1)'
}
check_eventually 60 "kubelet active on k8s-w2" active
check_eventually 120 "k8s-w2 Ready" w2_ready
check "eviction tuning kept: memory.available 200Mi/200M, nodefs.available 10%" tuning
verdict
