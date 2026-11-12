sed -i 's/args: \[wait-for, postgres,/args: [wait-for, postgresql,/' orders-api.yaml
grep -q 'wait-for, postgresql,' orders-api.yaml
kx apply -f orders-api.yaml >/dev/null
wait_rollout orders-db deploy/orders-api
