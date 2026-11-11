# K17: certSANs dropped from kubeadm-config, the API server cert re-issued from it (192.168.56.20 is gone)
nxi "$CP" >/dev/null <<'__X__'
set -eu
k() { kubectl --kubeconfig /etc/kubernetes/admin.conf "$@"; }
k -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > /var/tmp/k17-cc.yaml
python3 - <<'PY'
import json, yaml
cc = yaml.safe_load(open("/var/tmp/k17-cc.yaml"))
cc.get("apiServer", {}).pop("certSANs", None)
out = yaml.safe_dump(cc, sort_keys=False)
open("/var/tmp/k17-cc.yaml", "w").write(out)
json.dump({"data": {"ClusterConfiguration": out}}, open("/var/tmp/k17-patch.json", "w"))
init = [d for d in yaml.safe_load_all(open("/etc/kubernetes/kubeadm/init.yaml")) if d and d["kind"] == "InitConfiguration"][0]
yaml.safe_dump_all([init, cc], open("/var/tmp/k17-kubeadm.yaml", "w"), sort_keys=False)
PY
k -n kube-system patch cm kubeadm-config --type merge --patch-file /var/tmp/k17-patch.json >/dev/null
rm -f /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.key
kubeadm init phase certs apiserver --config /var/tmp/k17-kubeadm.yaml >/dev/null
rm -f /var/tmp/k17-*
# a changed manifest = a new static pod: `crictl stop` would be subject to the kubelet's restart back-off, which
# a selftest run (many API server restarts) drives to minutes
python3 - <<'PY'
import time, yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"; d = yaml.safe_load(open(f))
d["metadata"].setdefault("annotations", {})["lab.k8slab/cert-reissued"] = time.strftime("%Y-%m-%dT%H:%M:%S")
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
# (capture first: setup runs with pipefail, and the failing kx would fail "kx | grep -q x509" even on a match)
x509() { local o; o=$(KX_TIMEOUT=5s kx get --raw /readyz 2>&1) || true; grep -q x509 <<<"$o"; }
retry 300 x509 || die "the desktop still trusts the API endpoint"
