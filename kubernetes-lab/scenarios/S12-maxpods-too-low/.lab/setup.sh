# S12: each worker's kubelet maxPods set to exactly what it runs now - nothing new fits anywhere
for w in k8s-w1 k8s-w2 k8s-w3; do
  n=$(kx get pods -A --field-selector "spec.nodeName=$w,status.phase!=Succeeded,status.phase!=Failed" --no-headers | wc -l)
  nxi "$w" >/dev/null <<__X__
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d["maxPods"] = $n
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
done
capped() { for w in k8s-w1 k8s-w2 k8s-w3; do [ "$(kx get node "$w" -o jsonpath='{.status.allocatable.pods}')" -lt 110 ] || return 1; done; }
retry 120 capped || die "the workers still report 110 pods"
kns reports
kx -n reports create deployment reports --image=registry.lab:5000/lab/labapp:1.4 --replicas=3 --dry-run=client -o yaml | ka -f -
too_many() { kx -n reports get events -o jsonpath='{.items[*].message}' 2>/dev/null | grep -q 'Too many pods'; }
retry 120 too_many || die "no 'Too many pods' event"
