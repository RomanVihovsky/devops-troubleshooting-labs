small() { kx -n render get deploy render -o json | jq -e '.spec.template.spec.containers[0].resources.requests.cpu as $c
  | ($c | test("m$")) and (($c | rtrimstr("m") | tonumber) < 1000) or (($c | test("^[0-9.]+$")) and (($c | tonumber) < 1))' >/dev/null; }
check_eventually 120 "render rollout complete, all replicas Ready" deploy_ready render render
check "each pod requests less than 1 CPU" small
verdict
