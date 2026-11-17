# K07: kubeadm-config certificateValidityPeriod 4m, all certs renewed with it, control plane restarted -> expires
nxi "$CP" >/dev/null <<'__X__'
set -eu
k() { kubectl --kubeconfig /etc/kubernetes/admin.conf "$@"; }
k -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > /var/tmp/k07-cc.yaml
python3 - <<'PY'
import json, yaml
cc = yaml.safe_load(open("/var/tmp/k07-cc.yaml"))
cc["certificateValidityPeriod"] = "4m0s"       # ALERT-17: test the expiry alerts
out = yaml.safe_dump(cc, sort_keys=False)
json.dump({"data": {"ClusterConfiguration": out}}, open("/var/tmp/k07-patch.json", "w"))
init = [d for d in yaml.safe_load_all(open("/etc/kubernetes/kubeadm/init.yaml")) if d and d["kind"] == "InitConfiguration"][0]
yaml.safe_dump_all([init, cc], open("/var/tmp/k07-kubeadm.yaml", "w"), sort_keys=False)
PY
k -n kube-system patch cm kubeadm-config --type merge --patch-file /var/tmp/k07-patch.json >/dev/null
kubeadm certs renew all --config /var/tmp/k07-kubeadm.yaml >/dev/null 2>&1
rm -f /var/tmp/k07-*
python3 - <<'PY'
import time, yaml
for n in ("etcd", "kube-apiserver", "kube-controller-manager", "kube-scheduler"):
    f = f"/etc/kubernetes/manifests/{n}.yaml"; d = yaml.safe_load(open(f))
    d["metadata"].setdefault("annotations", {})["lab.k8slab/certs-renewed"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    yaml.safe_dump(d, open(f"/var/tmp/{n}.yaml", "w"), sort_keys=False)
PY
for n in etcd kube-apiserver kube-controller-manager kube-scheduler; do mv "/var/tmp/$n.yaml" "/etc/kubernetes/manifests/$n.yaml"; done
__X__
short() { nx "$CP" '! openssl x509 -checkend 600 -noout -in /etc/kubernetes/pki/apiserver.crt' </dev/null >/dev/null 2>&1; }
retry 60 short || die "the API server cert is not short-lived"
expired() { local o; o=$(KX_TIMEOUT=5s kx get --raw /readyz 2>&1) && return 1; grep -qiE 'expired|x509|refused|EOF|timeout' <<<"$o"; }
sleep 240
retry 300 expired || die "the certificates did not expire"
