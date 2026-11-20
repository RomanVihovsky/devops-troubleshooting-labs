nxi k8s-w1 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d.pop("podPidsLimit", None)
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
retry 120 nodes_ready || true
kx -n reports delete pod -l app=reports-api --wait=false >/dev/null
retry 150 deploy_ready reports reports-api 2 || true
