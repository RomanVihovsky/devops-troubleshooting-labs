probe_ok() { [ "$(kx -n edge get ds node-probe -o jsonpath='{.status.numberReady}/{.spec.template.spec.containers[0].ports[0].hostPort}' 2>/dev/null)" = 3/9100 ]; }
check_eventually 120 "edge-proxy rollout complete, all replicas Ready" deploy_ready edge edge-proxy
check_eventually 60 "http://edge-proxy.edge/ -> 200 inside the cluster" http_ok edge http://edge-proxy.edge/
check "node-probe runs on every worker with hostPort 9100" probe_ok
verdict
