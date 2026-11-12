default_sched() { [ "$(kx -n ml get pods -l app=ml-api --field-selector=status.phase=Running -o jsonpath='{.items[0].spec.schedulerName}' 2>/dev/null)" = default-scheduler ]; }
check_eventually 120 "ml-api rollout complete, Ready" deploy_ready ml ml-api
check "scheduled by default-scheduler" default_sched
verdict
