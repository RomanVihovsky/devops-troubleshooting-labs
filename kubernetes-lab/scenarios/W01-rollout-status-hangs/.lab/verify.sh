image() { kx -n storefront get deploy storefront -o jsonpath='{.spec.template.spec.containers[0].image}'; }
not_15() { [ "$(image)" != registry.lab:5000/lab/labapp:1.5 ]; }
no_stuck_rs() { ! kx -n storefront get rs -l app=storefront -o json | jq -e '[.items[] | select((.status.replicas // 0) > (.status.readyReplicas // 0))] | length > 0' >/dev/null; }
deadline() { [ "$(kx -n storefront get deploy storefront -o jsonpath='{.spec.progressDeadlineSeconds}')" -le 600 ]; }
check_eventually 180 "storefront: rollout complete, 3 Ready" deploy_ready storefront storefront 3
check "a version that starts (not 1.5)" not_15
check_eventually 60 "no ReplicaSet with unready pods" no_stuck_rs
check "progressDeadlineSeconds <= 600" deadline
verdict
