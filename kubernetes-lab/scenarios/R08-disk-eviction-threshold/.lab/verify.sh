no_pressure() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')" = False ]; }
sane() {
  nx k8s-w3 'cat /var/lib/kubelet/config.yaml' </dev/null | python3 -c 'import sys, yaml
v = str(((yaml.safe_load(sys.stdin) or {}).get("evictionHard") or {}).get("nodefs.available") or "10%")
sys.exit(0 if v.endswith("%") and float(v[:-1]) <= 15 else 1)'
}
on_w3() { [ "$(kx -n ingest get pods -l app=ingest --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u)" = k8s-w3 ]; }
check_eventually 120 "k8s-w3: no DiskPressure" no_pressure
check "w3's kubelet nodefs.available threshold <= 15% (or the default)" sane
check_eventually 180 "ingest: 2 Ready pods" deploy_ready ingest ingest 2
check "ingest runs on k8s-w3" on_w3
check_eventually 120 "all nodes Ready" nodes_ready
verdict
