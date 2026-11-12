etcd_raw() { nx "$CP" "etcdctl $ETCD_FLAGS get /registry/secrets/t16/$1 --print-value-only 2>/dev/null | head -c 64" </dev/null; }
encrypted() { etcd_raw "$1" | grep -aq '^k8s:enc:'; }
api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
fresh_encrypted() {
  local n="probe-$RANDOM" r=1
  kx -n t16 create secret generic "$n" --from-literal=x=y >/dev/null 2>&1 || return 1
  encrypted "$n" && r=0
  kx -n t16 delete secret "$n" --wait=false >/dev/null 2>&1
  return $r
}
T0=$(date -u +%FT%TZ)
audited() {
  kx -n t16 get secret legacy >/dev/null 2>&1
  nx "$CP" "tail -n 500 /var/log/kubernetes/audit/audit.log 2>/dev/null | jq -c 'select(.objectRef.resource == \"secrets\" and .objectRef.namespace == \"t16\" and .objectRef.name == \"legacy\" and .verb == \"get\")' | tail -1" </dev/null \
    | jq -e --arg t0 "$T0" '.level == "Metadata" and .requestReceivedTimestamp >= $t0 and (has("responseObject") | not)' >/dev/null
}
psa_label() { [ "$(kx get ns t16 -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" = restricted ]; }
psa_rejects() { kx -n t16 run psa-probe --image="$BUSYBOX_IMAGE" --privileged --dry-run=server --command -- true 2>&1 | grep -q 'violates PodSecurity'; }
check_eventually 120 "the API server answers" api_ok
check "t16/legacy is encrypted in etcd (re-encrypted)" encrypted legacy
check "a new Secret is encrypted in etcd" fresh_encrypted
check_eventually 30 "reading a Secret leaves a Metadata-level audit event" audited
check "namespace t16 enforces restricted" psa_label
check "a privileged pod is rejected in t16" psa_rejects
check_eventually 120 "all nodes Ready" nodes_ready
verdict
