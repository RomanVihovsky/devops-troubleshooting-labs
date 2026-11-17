sane() {
  nx k8s-w1 'cat /var/lib/kubelet/config.yaml' </dev/null | python3 -c 'import sys, yaml
v = (yaml.safe_load(sys.stdin) or {}).get("podPidsLimit")
sys.exit(0 if v is None or int(v) < 0 or int(v) >= 1024 else 1)'
}
kept() {
  [ "$(kx -n reports get deploy reports-api -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/hostname} {.spec.template.spec.containers[0].env[?(@.name=="WORKER_THREADS")].value}')" = "k8s-w1 100" ]
}
on_w1() { [ "$(kx -n reports get pods -l app=reports-api --field-selector=status.phase=Running -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u)" = k8s-w1 ]; }
check "w1's kubelet podPidsLimit is unset or >= 1024" sane
check "reports-api still pinned to k8s-w1 with WORKER_THREADS=100" kept
check_eventually 150 "reports-api: 2 Ready pods" deploy_ready reports reports-api 2
check "they run on k8s-w1" on_w1
check_eventually 150 "stable for 60 s" stable_for 60 reports app=reports-api
verdict
