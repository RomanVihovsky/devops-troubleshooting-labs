# N01: Service selector "app: backend" vs pod label "app: back-end" -> no endpoints
kns orders
ka -f "$SCN/manifests/orders.yaml"
wait_rollout orders deploy/backend
wait_rollout orders deploy/frontend
