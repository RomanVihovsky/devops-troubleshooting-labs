running() { [ "$(kx -n analytics2 get pods -l app=analytics --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)" = 2 ]; }
sized() { kx -n analytics2 get deploy analytics -o json | python3 -c 'import json, re, sys
r = json.load(sys.stdin)["spec"]["template"]["spec"]["containers"][0].get("resources") or {}
def b(q):
    n, u = re.fullmatch(r"([0-9.]+)([KMGT]i?)?", str(q)).groups()
    return float(n) * {"Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "Ti": 2**40, "K": 1e3, "M": 1e6, "G": 1e9, "T": 1e12, None: 1}[u]
req = (r.get("requests") or {}).get("memory"); lim = (r.get("limits") or {}).get("memory")
sys.exit(0 if req and lim and b(req) <= 512 * 2**20 else 1)'; }
check_eventually 120 "analytics: 2 Running pods" running
check "memory request <= 512Mi, request and limit set" sized
verdict
