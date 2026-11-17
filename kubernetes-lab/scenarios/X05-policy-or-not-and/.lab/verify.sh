protected() { [ -n "$(kx -n db get networkpolicy -o json | jq -r '.items[] | select(.spec.podSelector.matchLabels.app == "orders-db" and ((.spec.policyTypes // []) | index("Ingress"))) | .metadata.name')" ]; }
check "a NetworkPolicy (Ingress) still selects orders-db" protected
check_reach <<'ROWS'
monitoring app=prometheus orders-db.db.svc:5432 open
monitoring app=node-exporter orders-db.db.svc:5432 blocked
monitoring - orders-db.db.svc:5432 blocked
db app=prometheus orders-db.db.svc:5432 blocked
ROWS
verdict
