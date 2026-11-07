selftest_kept() { dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec}}' app_web | grep -q 'SELFTEST_ROUNDS=30000' &&
                  dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Healthcheck.Test}}' app_web | grep -q health; }
health_fast() {
  local n t
  for n in "${BASE_NODES[@]}"; do
    t=$(curl -fsS -o /dev/null -w '%{time_total}' --max-time 3 "http://$(node_ip "$n"):$APP_PORT/health") || return 1
    awk -v t="$t" 'BEGIN{exit !(t < 1.0)}' || return 1
  done
}
check_eventually 60 "app_web is 2/2" svc_converged app_web
check "no task replaced for 15 s" svc_stable app_web 15
check "self-test and healthcheck still configured" selftest_kept
check_eventually 20 "/health answers in < 1 s via every node" health_fast
verdict
