nxi "$CP" >/dev/null <<'__X__'
set -eu
key=$(head -c 32 /dev/urandom | base64)
sed -i "s|secret: .*}|secret: $key}|" /etc/kubernetes/enc/enc.yaml
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"; d = yaml.safe_load(open(f)); c = d["spec"]["containers"][0]
c["volumeMounts"].append({"name": "k8s-enc", "mountPath": "/etc/kubernetes/enc", "readOnly": True})
d["spec"]["volumes"].append({"name": "k8s-enc", "hostPath": {"path": "/etc/kubernetes/enc", "type": "DirectoryOrCreate"}})
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
sleep 20
retry 240 kx get --raw /readyz || die "API not back"
kx get secrets -A -o json | kx replace -f - >/dev/null 2>&1 || true
retry 180 nodes_ready || true
