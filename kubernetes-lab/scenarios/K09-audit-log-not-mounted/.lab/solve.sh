nxi "$CP" >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"
d = yaml.safe_load(open(f))
c = d["spec"]["containers"][0]
c["volumeMounts"].append({"name": "audit-log", "mountPath": "/var/log/kubernetes/audit"})
d["spec"]["volumes"].append({"name": "audit-log", "hostPath": {"path": "/var/log/kubernetes/audit", "type": "DirectoryOrCreate"}})
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
up() { [ "$(kx get --raw /readyz 2>/dev/null)" = ok ]; }
retry 240 up || true
