nxi "$CP" >/dev/null <<'__X__'
set -eu
sed '/--quota-backend-bytes=/d' /etc/kubernetes/manifests/etcd.yaml > /var/tmp/etcd.yaml
mv /var/tmp/etcd.yaml /etc/kubernetes/manifests/etcd.yaml
__X__
# wait for the NEW etcd (no quota flag) - disarming the old one is undone at once while it's over quota. The alarm
# is persisted: the new etcd starts with NOSPACE too, until it's disarmed
new_etcd() {
  local p; p=$(nx "$CP" 'pgrep -a -x etcd' </dev/null 2>/dev/null) || return 1
  grep -q -- '--data-dir' <<<"$p" && ! grep -q -- '--quota-backend-bytes' <<<"$p" \
    && nx "$CP" "etcdctl $ETCD_FLAGS endpoint status" </dev/null >/dev/null 2>&1   # `endpoint health` fails while an alarm is active
}
retry 240 new_etcd || die "etcd did not restart without the quota"
nx "$CP" "etcdctl $ETCD_FLAGS alarm disarm" </dev/null >/dev/null
retry 240 kx get --raw /readyz || die "API not back"
junk_gone() { kx -n import delete configmap --all >/dev/null 2>&1; [ -z "$(kx -n import get configmaps -o name 2>/dev/null | grep -- '-cache$')" ]; }
retry 120 junk_gone || true
rev=$(nx "$CP" "etcdctl $ETCD_FLAGS endpoint status -w json" </dev/null | jq '.[0].Status.header.revision')
nx "$CP" "etcdctl $ETCD_FLAGS compact $rev >/dev/null; etcdctl $ETCD_FLAGS defrag >/dev/null; etcdctl $ETCD_FLAGS alarm disarm >/dev/null" </dev/null
retry 180 nodes_ready || true
