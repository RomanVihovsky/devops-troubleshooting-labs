colocated() {
  local cn; cn=$(kx -n sessions get pods -l app=redis-cache -o jsonpath='{.items[0].spec.nodeName}')
  [ -n "$cn" ] && [ "$(kx -n sessions get pods -l app=session-api --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c | awk '{print $1" "$2}')" = "2 $cn" ]
}
required() { kx -n sessions get deploy session-api -o json | jq -e '.spec.template.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution | length > 0' >/dev/null; }
check_eventually 120 "session-api: 2 Running pods on the cache's node" colocated
check "still a required pod affinity" required
verdict
