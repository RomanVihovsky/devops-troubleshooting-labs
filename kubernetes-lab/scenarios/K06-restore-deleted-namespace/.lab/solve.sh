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
retry 180 deploy_ready prod orders 2 || true
