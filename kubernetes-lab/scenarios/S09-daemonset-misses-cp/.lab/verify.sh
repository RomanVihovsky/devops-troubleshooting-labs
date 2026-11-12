all4() { [ "$(kx -n logging get ds log-agent -o jsonpath='{.status.desiredNumberScheduled}/{.status.numberReady}' 2>/dev/null)" = 4/4 ]; }
cp_taint() { kx get node "$CP" -o jsonpath='{.spec.taints[*].key}' | grep -q node-role.kubernetes.io/control-plane; }
check_eventually 120 "log-agent desired + ready on all 4 nodes" all4
check "k8s-cp1 keeps its control-plane taint" cp_taint
verdict
