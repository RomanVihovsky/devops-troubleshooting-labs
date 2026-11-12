none_terminating() { ! kx -n queue get pods -o json | jq -e '[.items[] | select(.metadata.deletionTimestamp != null or ((.metadata.finalizers // []) | index("example.com/cleanup")))] | length > 0' >/dev/null; }
graceful() { kx -n queue get deploy queue-worker -o json | jq -e '.spec.template.spec as $s
  | (($s.terminationGracePeriodSeconds // 30) <= 60)
    and ([$s.containers[0].env[]? | select(.name == "SHUTDOWN_MODE" and .value == "ignore")] | length == 0)' >/dev/null; }
check_eventually 60 "no queue-worker pod Terminating or with the example.com/cleanup finalizer" none_terminating
check_eventually 120 "queue-worker: 1 Ready pod" deploy_ready queue queue-worker 1
check "the pods stop gracefully: SHUTDOWN_MODE not ignore, grace <= 60 s" graceful
verdict
