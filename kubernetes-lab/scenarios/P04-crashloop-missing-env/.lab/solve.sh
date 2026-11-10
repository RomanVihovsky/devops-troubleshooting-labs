sed -i 's/name: DB_URL/name: DATABASE_URL/' billing.yaml
kx apply -f billing.yaml >/dev/null
wait_rollout billing deploy/billing
