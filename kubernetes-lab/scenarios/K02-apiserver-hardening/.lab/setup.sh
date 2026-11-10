# K02: profiling off (valid), PodSecurityPolicy admission (gone since 1.25), a wrong cert path, an invalid label
nxi "$CP" >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
d = yaml.safe_load(open("/etc/kubernetes/manifests/kube-apiserver.yaml"))
cmd = d["spec"]["containers"][0]["command"]
def setflag(name, val):
    for i, a in enumerate(cmd):
        if a.startswith("--%s=" % name): cmd[i] = "--%s=%s" % (name, val); return
    cmd.append("--%s=%s" % (name, val))
setflag("profiling", "false")
setflag("enable-admission-plugins", "NodeRestriction,PodSecurityPolicy")
setflag("tls-cert-file", "/etc/kubernetes/pki/apiserver.cert")
d["metadata"].setdefault("labels", {})["hardened-by"] = "sec team"
yaml.safe_dump(d, open("/var/tmp/k02-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/k02-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
api_down() { ! KX_TIMEOUT=5s kx get --raw /readyz >/dev/null 2>&1; }
retry 180 api_down || die "the API never went down"
