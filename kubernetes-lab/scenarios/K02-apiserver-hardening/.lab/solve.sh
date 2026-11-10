nxi "$CP" >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
d = yaml.safe_load(open("/etc/kubernetes/manifests/kube-apiserver.yaml"))
cmd = d["spec"]["containers"][0]["command"]
for i, a in enumerate(cmd):
    if a.startswith("--enable-admission-plugins="): cmd[i] = "--enable-admission-plugins=NodeRestriction"
    if a.startswith("--tls-cert-file="): cmd[i] = "--tls-cert-file=/etc/kubernetes/pki/apiserver.crt"
d["metadata"]["labels"]["hardened-by"] = "sec-team"
yaml.safe_dump(d, open("/var/tmp/k02-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/k02-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
retry 240 kx get --raw /readyz || die "API not back"
