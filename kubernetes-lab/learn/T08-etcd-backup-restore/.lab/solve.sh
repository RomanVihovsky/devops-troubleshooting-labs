nx "$CP" "mkdir -p /var/backups && etcdctl $ETCD_FLAGS snapshot save /var/backups/etcd-t08.db >/dev/null 2>&1 && etcdutl snapshot status /var/backups/etcd-t08.db >/dev/null 2>&1" </dev/null
kx delete namespace t08 --wait=false >/dev/null              # the accident
gone() { ! kx get namespace t08 >/dev/null 2>&1; }
retry 120 gone || true
ip=$(node_ip "$CP")
nxi "$CP" >/dev/null 2>&1 <<__X__
set -e
etcdutl snapshot restore /var/backups/etcd-t08.db --data-dir /var/lib/etcd-t08 --name $CP \
  --initial-cluster $CP=https://$ip:2380 --initial-advertise-peer-urls https://$ip:2380
sed -i 's|^\(\s*\)path: /var/lib/etcd\$|\1path: /var/lib/etcd-t08|' /etc/kubernetes/manifests/etcd.yaml
grep -q 'path: /var/lib/etcd-t08' /etc/kubernetes/manifests/etcd.yaml
__X__
etcd_up() { nx "$CP" "etcdctl $ETCD_FLAGS endpoint health" </dev/null; }
sleep 20   # kubelet notices the manifest change and restarts etcd
retry 180 etcd_up || die "etcd did not come back from the restored data"
nx "$CP" 'crictl stop $(crictl ps --name kube-apiserver -q) >/dev/null 2>&1; true' </dev/null
retry 180 kx get --raw /readyz || die "API not back after the restore"
retry 180 nodes_ready || true
