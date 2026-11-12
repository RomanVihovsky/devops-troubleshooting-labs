nxi k8s-w2 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d.pop("evictionHard", None)
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
kx -n payments set resources deploy/payments-api --requests=cpu=100m,memory=256Mi --limits=cpu=100m,memory=256Mi >/dev/null
nopress() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="MemoryPressure")].status}')" = False ]; }
retry 120 nopress || true
wait_rollout payments deploy/payments-api 240 || true
