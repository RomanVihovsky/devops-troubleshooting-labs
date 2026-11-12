spec() { kx -n thumbs get deploy thumbs -o json; }
cache_mb() { spec | jq -r '.spec.template.spec.containers[0].env[] | select(.name == "DISK_CACHE_MB") | .value'; }
# /tmp/cache is a volume: emptyDir with sizeLimit >= 300Mi, or a PVC
sized_volume() { spec | python3 -c 'import json, re, sys
d = json.load(sys.stdin)["spec"]["template"]["spec"]
m = [v for v in d["containers"][0].get("volumeMounts", []) if v["mountPath"].rstrip("/") == "/tmp/cache"]
if not m: sys.exit(1)
v = [x for x in d.get("volumes", []) if x["name"] == m[0]["name"]][0]
if "persistentVolumeClaim" in v: sys.exit(0)
s = (v.get("emptyDir") or {}).get("sizeLimit")
if not s: sys.exit(1)
n, u = re.fullmatch(r"([0-9.]+)([KMGT]i?)?", str(s)).groups()
f = {"Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "Ti": 2**40, "K": 1e3, "M": 1e6, "G": 1e9, "T": 1e12, None: 1}[u]
sys.exit(0 if float(n) * f >= 300 * 2**20 else 1)'; }
no_new_evictions() {
  local t=60; [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3
  local n0; n0=$(kx -n thumbs get pods --no-headers 2>/dev/null | grep -c Evicted)
  sleep "$t"; [ "$(kx -n thumbs get pods --no-headers 2>/dev/null | grep -c Evicted)" = "$n0" ] && deploy_ready thumbs thumbs 2
}
check "DISK_CACHE_MB is still 300" test "$(cache_mb)" = 300
check "/tmp/cache is a sized volume (emptyDir sizeLimit >= 300Mi, or a PVC)" sized_volume
check_eventually 180 "thumbs: 2 Ready pods" deploy_ready thumbs thumbs 2
check_eventually 150 "no new evictions for 60 s" no_new_evictions
verdict
