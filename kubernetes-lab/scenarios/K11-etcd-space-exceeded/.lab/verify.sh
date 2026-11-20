no_alarm() { [ -z "$(nx "$CP" "etcdctl $ETCD_FLAGS alarm list" </dev/null 2>/dev/null)" ]; }
writes() {
  local n="lab-k11-$RANDOM"
  kx -n default create configmap "$n" --from-literal=ok=1 >/dev/null 2>&1 && kx -n default delete configmap "$n" >/dev/null 2>&1
}
quota_ok() {
  local q; q=$(nx "$CP" "grep -o -- '--quota-backend-bytes=[0-9]*' /etc/kubernetes/manifests/etcd.yaml" </dev/null 2>/dev/null | cut -d= -f2)
  [ -z "$q" ] || [ "$q" -ge 1073741824 ]
}
no_junk() { [ "$(kx -n import get configmaps -o name 2>/dev/null | grep -c -- '-cache$')" = 0 ]; }
check "etcd has no active alarm" no_alarm
check_eventually 60 "writes work again" writes
check "the backend quota is the default or >= 1 GiB" quota_ok
check "namespace import has no cache ConfigMaps" no_junk
check_eventually 180 "all nodes Ready" nodes_ready
verdict
