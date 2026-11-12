nxi k8s-w3 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d.pop("evictionHard", None)
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
nopress() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')" = False ]; }
retry 120 nopress || true
wait_rollout ingest deploy/ingest 240 || true
