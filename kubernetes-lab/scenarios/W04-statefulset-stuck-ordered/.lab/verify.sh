ready3() { [ "$(kx -n quorum get sts quorum -o jsonpath='{.status.readyReplicas}')" = 3 ]; }
ordered() { [ "$(kx -n quorum get sts quorum -o jsonpath='{.spec.podManagementPolicy}')" = OrderedReady ]; }
probe() { [ -n "$(kx -n quorum get sts quorum -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}')" ]; }
check_eventually 180 "quorum: 3/3 Ready" ready3
check "still OrderedReady" ordered
check "still a readiness probe" probe
verdict
