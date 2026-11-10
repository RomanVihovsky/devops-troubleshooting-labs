has_liveness() { [ -n "$(kx -n profile get deploy profile -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null)" ]; }
check_eventually 120 "profile rollout complete, all replicas Ready" deploy_ready profile profile
check_eventually 150 "no new restarts for 60 s" stable_for 60 profile app=profile
check "a liveness probe is still configured" has_liveness
verdict
