init_kept() { kx -n orders-db get deploy orders-api -o json | jq -e '.spec.template.spec.initContainers | length >= 1' >/dev/null; }
check_eventually 120 "orders-api rollout complete, Ready" deploy_ready orders-db orders-api
check "it still waits for the database in an init container" init_kept
verdict
