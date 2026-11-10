cache_kept() { kx -n search-cache get deploy search-cache -o json | jq -e '[.spec.template.spec.containers[0].env[] | select(.name == "CACHE_MB" and .value == "192")] | length == 1' >/dev/null; }
check_eventually 120 "search-cache rollout complete, Ready" deploy_ready search-cache search-cache
check_eventually 120 "no new restarts for 60 s" stable_for 60 search-cache app=search-cache
check "CACHE_MB still 192" cache_kept
verdict
