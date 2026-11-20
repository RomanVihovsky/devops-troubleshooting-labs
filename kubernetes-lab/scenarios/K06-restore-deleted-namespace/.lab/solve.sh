ip=$(node_ip "$CP")
nxi "$CP" >/dev/null 2>&1 <<__X__
set -e
etcdutl snapshot restore /var/backups/etcd/etcd-nightly.db --data-dir /var/lib/etcd-restored --name $CP \
  --initial-cluster $CP=https://$ip:2380 --initial-advertise-peer-urls https://$ip:2380
sed -i 's|^\(\s*\)path: /var/lib/etcd\$|\1path: /var/lib/etcd-restored|' /etc/kubernetes/manifests/etcd.yaml
grep -q 'path: /var/lib/etcd-restored' /etc/kubernetes/manifests/etcd.yaml
__X__
etcd_up() { nx "$CP" "etcdctl $ETCD_FLAGS endpoint health" </dev/null; }
sleep 20
retry 180 etcd_up || die "etcd did not come back from the restored data"
nx "$CP" 'crictl stop $(crictl ps --name kube-apiserver -q) >/dev/null 2>&1; true' </dev/null
retry 180 kx get --raw /readyz || die "API not back after the restore"
retry 180 nodes_ready || true
# the kubelets' watches point at revisions newer than the restored store and stall: restart them
for n in $(cluster_nodes); do nx "$n" 'systemctl restart kubelet' </dev/null; done
sleep 15; retry 180 nodes_ready || true
# ...and the node agents that watch the API too (calico-node: no routes/policy for new pods, kube-proxy)
kx -n kube-system rollout restart ds/calico-node ds/kube-proxy >/dev/null
kx -n kube-system rollout status ds/calico-node --timeout=300s >/dev/null 2>&1 || true
kx -n kube-system rollout status ds/kube-proxy --timeout=200s >/dev/null 2>&1 || true
# pods restored from etcd are ghosts - no kubelet will ever confirm their deletion, so force it (their kubelets already killed those UIDs): recreate them
kx -n prod delete pod --all --grace-period=0 --force >/dev/null 2>&1
retry 180 deploy_ready prod orders 2 || true
