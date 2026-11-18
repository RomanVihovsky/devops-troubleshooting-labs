ip=$(node_ip "$CP")
nxi "$CP" >/dev/null 2>&1 <<__X__
set -e
kubeadm certs renew apiserver --config /etc/kubernetes/kubeadm/init.yaml
etcdutl snapshot restore /var/backups/etcd/nightly.db --data-dir /var/lib/etcd-restored --name $CP \
  --initial-cluster $CP=https://$ip:2380 --initial-advertise-peer-urls https://$ip:2380
sed -i 's|^\(\s*\)path: /var/lib/etcd\$|\1path: /var/lib/etcd-restored|' /etc/kubernetes/manifests/etcd.yaml
python3 - <<'PY'
import time, yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"; d = yaml.safe_load(open(f))
d["metadata"].setdefault("annotations", {})["lab.k8slab/cert-test"] = "renewed-" + time.strftime("%H%M%S")
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
sleep 30
retry 240 kx get --raw /readyz || die "API not back"
retry 180 nodes_ready || true
# the kubelets' watches point at revisions newer than the restored store and stall: restart them
for n in $(cluster_nodes); do nx "$n" 'systemctl restart kubelet' </dev/null; done
sleep 15; retry 180 nodes_ready || true
# ...and the node agents that watch the API too (calico-node: no routes/policy for new pods, kube-proxy)
kx -n kube-system rollout restart ds/calico-node ds/kube-proxy >/dev/null
kx -n kube-system rollout status ds/calico-node --timeout=300s >/dev/null 2>&1 || true
kx -n kube-system rollout status ds/kube-proxy --timeout=200s >/dev/null 2>&1 || true
# pods restored from etcd are ghosts - no kubelet will ever confirm their deletion, so force it (their kubelet already killed those UIDs): recreate them
kx -n prod delete pod --all --grace-period=0 --force >/dev/null 2>&1
retry 180 deploy_ready prod ledger 1 || true
