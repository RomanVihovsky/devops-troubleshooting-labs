nxi "$CP" >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/kube-controller-manager.yaml"; d = yaml.safe_load(open(f)); c = d["spec"]["containers"][0]
c["command"] += ["--cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt", "--cluster-signing-key-file=/etc/kubernetes/pki/ca.key"]
yaml.safe_dump(d, open("/var/tmp/kcm.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kcm.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml
__X__
retry 180 csr_issued lab-onboard-ana || true
