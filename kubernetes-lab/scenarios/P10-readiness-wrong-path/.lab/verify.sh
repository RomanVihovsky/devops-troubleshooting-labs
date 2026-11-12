has_readiness() { [ -n "$(kx -n quotes get deploy quotes -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)" ]; }
check_eventually 120 "quotes rollout complete, all replicas Ready" deploy_ready quotes quotes
check_eventually 60 "Service quotes has endpoints" has_endpoints quotes quotes
check_eventually 60 "http://quotes.quotes/ -> 200 inside the cluster" http_ok quotes http://quotes.quotes/
check "a readiness probe is still configured" has_readiness
verdict
