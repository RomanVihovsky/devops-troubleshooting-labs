nxi "$CP" >/dev/null <<'__X__'
set -eu
sed 's|path: /var/lib/etcd-disks$|path: /var/lib/etcd-disk|' /etc/kubernetes/manifests/etcd.yaml > /var/tmp/etcd.yaml
mv /var/tmp/etcd.yaml /etc/kubernetes/manifests/etcd.yaml
__X__
retry 240 kx get --raw /readyz || die "API not back"
retry 180 nodes_ready || true
