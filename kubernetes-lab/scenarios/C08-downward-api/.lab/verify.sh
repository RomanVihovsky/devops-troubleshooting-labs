# every Running pod: POD_IP = its IP, MEMORY_LIMIT_MB = 256
env_right() {
  local p ip e n=0
  for p in $(kx -n inventory get pods -l app=inventory --field-selector=status.phase=Running -o name 2>/dev/null); do
    ip=$(kx -n inventory get "$p" -o jsonpath='{.status.podIP}')
    e=$(kx -n inventory exec "$p" -- labapp get http://localhost:8080/env 2>/dev/null) || return 1
    [ "$(jq -r '.POD_IP + "/" + .MEMORY_LIMIT_MB' <<<"$e")" = "$ip/256" ] || return 1
    n=$((n + 1))
  done
  [ $n -ge 2 ]
}
downward() { kx -n inventory get deploy inventory -o json | jq -e '.spec.template.spec.containers[0].env as $e
  | ([$e[] | select(.name == "POD_IP" and .valueFrom.fieldRef.fieldPath == "status.podIP")] | length == 1)
    and ([$e[] | select(.name == "MEMORY_LIMIT_MB" and .valueFrom.resourceFieldRef.resource == "limits.memory")] | length == 1)' >/dev/null; }
check_eventually 150 "inventory: 2 Ready pods" deploy_ready inventory inventory 2
check_eventually 60 "each pod: POD_IP = its IP, MEMORY_LIMIT_MB = 256" env_right
check "both come from the Downward API" downward
verdict
