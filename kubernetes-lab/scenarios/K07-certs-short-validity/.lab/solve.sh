nxi "$CP" >/dev/null 2>&1 <<'__X__'
set -eu
# the API is down: build the kubeadm configuration from the local files, without the short lifetime
python3 - <<'PY'
import yaml
docs = [d for d in yaml.safe_load_all(open("/etc/kubernetes/kubeadm/init.yaml")) if d]
for d in docs:
    d.pop("certificateValidityPeriod", None)
yaml.safe_dump_all(docs, open("/var/tmp/k07-fix.yaml", "w"), sort_keys=False)
PY
kubeadm certs renew all --config /var/tmp/k07-fix.yaml >/dev/null
python3 - <<'PY'
import time, yaml
for n in ("etcd", "kube-apiserver", "kube-controller-manager", "kube-scheduler"):
    f = f"/etc/kubernetes/manifests/{n}.yaml"; d = yaml.safe_load(open(f))
    d["metadata"].setdefault("annotations", {})["lab.k8slab/certs-renewed"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    yaml.safe_dump(d, open(f"/var/tmp/{n}.yaml", "w"), sort_keys=False)
PY
for n in etcd kube-apiserver kube-controller-manager kube-scheduler; do mv "/var/tmp/$n.yaml" "/etc/kubernetes/manifests/$n.yaml"; done
rm -f /var/tmp/k07-fix.yaml
__X__
sleep 20
retry 240 kx get --raw /readyz || die "API not back"
cc=$(kx -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' | python3 -c 'import json, sys, yaml
cc = yaml.safe_load(sys.stdin); cc.pop("certificateValidityPeriod", None); print(json.dumps({"data": {"ClusterConfiguration": yaml.safe_dump(cc, sort_keys=False)}}))')
kx -n kube-system patch cm kubeadm-config --type merge -p "$cc" >/dev/null
retry 180 nodes_ready || true
