nonroot() { [ "$(kx -n uploads get deploy uploads -o jsonpath='{.spec.template.spec.securityContext.runAsUser}')" = 1000 ] \
            && ! kx -n uploads get deploy uploads -o json | jq -e '[.spec.template.spec | (.initContainers // []) + .containers | .[] | .securityContext.runAsUser // empty | select(. == 0)] | length > 0' >/dev/null; }
restricted() { [ "$(kx get ns uploads -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" = restricted ]; }
shared_write() {
  local a b v="v05-$RANDOM"
  read -r a b < <(kx -n uploads get pods -l app=uploads --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')
  [ -n "$b" ] || return 1
  kx -n uploads exec "$a" -- labapp get -X PUT -d "$v" http://localhost:8080/kv/v05 >/dev/null 2>&1 || return 1
  [ "$(kx -n uploads exec "$b" -- labapp get http://localhost:8080/kv/v05 2>/dev/null)" = "$v" ]
}
check_eventually 180 "uploads: 2 Ready pods" deploy_ready uploads uploads 2
check_eventually 60 "a value written through one pod is read back through the other" shared_write
check "the pods run as uid 1000 (no root container)" nonroot
check "namespace uploads still enforces restricted" restricted
verdict
