sed -i 's|^      containers:|      tolerations: [{key: dedicated, operator: Equal, value: batch, effect: NoSchedule}]\n      containers:|' etl.yaml
kx apply -f etl.yaml >/dev/null
wait_rollout etl deploy/etl
