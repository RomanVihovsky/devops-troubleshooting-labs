# L03: evictionHard with an invalid quantity ("200MB") - the kubelet refuses to start
nxi k8s-w2 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d["evictionHard"] = {"memory.available": "200MB", "nodefs.available": "10%"}
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet || true
__X__
notready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 notready || die "k8s-w2 stayed Ready"
