pg_ready() { [ "$(kx -n orders-db get pod postgres-0 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
pvc_bound() {
  [ "$(kx -n orders-db get pvc data-postgres-0 -o jsonpath='{.status.phase}' 2>/dev/null)" = Bound ] \
    && [ "$(kx -n orders-db get pod postgres-0 -o jsonpath='{.spec.volumes[?(@.name=="data")].persistentVolumeClaim.claimName}' 2>/dev/null)" = data-postgres-0 ]
}
dns_ok() {
  local ip; ip=$(kx -n orders-db get pod postgres-0 -o jsonpath='{.status.podIP}' 2>/dev/null)
  [ -n "$ip" ] && kx -n orders-db exec deploy/orders -- python3 -c "import socket, sys; sys.exit(0 if socket.gethostbyname('postgres-0.postgres.orders-db.svc') == '$ip' else 1)" >/dev/null 2>&1
}
items() { local o; o=$(kx -n orders-db exec deploy/orders -- labapp get http://localhost:8080/items 2>/dev/null) || return 1; jq -e '(.items // .) | length > 0' <<<"$o" >/dev/null 2>&1; }
check_eventually 150 "postgres-0 is Ready" pg_ready
check "postgres-0 runs on the Bound PVC data-postgres-0" pvc_bound
check_eventually 60 "postgres-0.postgres.orders-db.svc resolves to postgres-0" dns_ok
check_eventually 150 "orders is Ready (connected, schema migrated)" deploy_ready orders-db orders 1
check_eventually 30 "orders serves its items" items
if [ -z "${LAB_EXPECT_FAIL:-}" ]; then
  kx -n orders-db delete pod postgres-0 --wait=true >/dev/null 2>&1
  check_eventually 150 "postgres-0 back after a restart" pg_ready
  check_eventually 120 "the items are still there (data on the volume)" items
fi
verdict
