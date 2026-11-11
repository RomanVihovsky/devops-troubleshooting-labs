no_pressure() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="MemoryPressure")].status}')" = False ]; }
# memory.available hard threshold: unset (default 100Mi) or <= 500Mi; a percentage is judged against 4 GiB
sane() {
  nx k8s-w2 'cat /var/lib/kubelet/config.yaml' </dev/null | python3 -c 'import re, sys, yaml
v = str(((yaml.safe_load(sys.stdin) or {}).get("evictionHard") or {}).get("memory.available") or "100Mi")
u = {"Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "K": 1e3, "M": 1e6, "G": 1e9, "": 1}
if v.endswith("%"):
    b = float(v[:-1]) / 100 * 4 * 2**30
else:
    m = re.fullmatch(r"([0-9.]+)([KMG]i?)?", v); b = float(m.group(1)) * u[m.group(2) or ""] if m else 1e12
sys.exit(0 if b <= 500 * 2**20 else 1)'
}
guaranteed() { [ "$(kx -n payments get pods -l app=payments-api --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.status.qosClass}{" "}{.spec.nodeName}{"\n"}{end}' | sort -u)" = "Guaranteed k8s-w2" ]; }
check_eventually 120 "k8s-w2: no MemoryPressure" no_pressure
check "w2's kubelet memory.available threshold <= 500Mi (or the default)" sane
check_eventually 180 "payments-api: 2 Ready pods" deploy_ready payments payments-api 2
check "payments-api pods are Guaranteed and on k8s-w2" guaranteed
check_eventually 150 "payments-api stable for 60 s" stable_for 60 payments app=payments-api
verdict
