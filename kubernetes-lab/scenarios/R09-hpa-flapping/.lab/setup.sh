# R09: scaleDown stabilization 0 + bursty load: the HPA follows every burst up and every gap down
kns catalog
ka -f catalog-api.yaml
wait_rollout catalog deploy/catalog-api
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: traffic-replay, namespace: catalog}
spec:
  replicas: 1
  selector: {matchLabels: {app: traffic-replay}}
  template:
    metadata: {labels: {app: traffic-replay}}
    spec:
      containers:
        - name: replay
          image: registry.lab:5000/lab/labapp:1.4
          command: ["sh", "-c", "while true; do labapp load http://catalog-api.catalog.svc:8080/ -c 4 -d 25 --rps 200 -q; sleep 35; done"]
          resources: {requests: {cpu: 50m, memory: 32Mi}}
YML
wait_rollout catalog deploy/traffic-replay
down_event() { local o; o=$(kx -n catalog get events --field-selector involvedObject.name=catalog-api,reason=SuccessfulRescale -o jsonpath='{.items[*].message}' 2>/dev/null) || true; grep -q 'below target' <<<"$o"; }
retry 300 down_event || die "the HPA never scaled down after a burst"
