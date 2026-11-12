liveness_same() { [ "$(kx -n analytics get deploy analytics -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}/{.spec.template.spec.containers[0].livenessProbe.periodSeconds}/{.spec.template.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null)" = 10/5/3 ]; }
warmup_kept() { kx -n analytics get deploy analytics -o json | jq -e '[.spec.template.spec.containers[0].env[] | select(.name == "WARMUP_SECONDS" and .value == "45")] | length == 1' >/dev/null; }
check_eventually 180 "analytics rollout complete, Ready" deploy_ready analytics analytics
check_eventually 150 "no new restarts for 60 s" stable_for 60 analytics app=analytics
check "liveness unchanged (10 s delay, 5 s period, 3 failures)" liveness_same
check "the 45 s warm-up is still there" warmup_kept
verdict
