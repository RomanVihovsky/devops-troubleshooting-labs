# Q02: one container of a two-container pod was OOM-killed once ("the nightly run"); find the facts
kns nightly
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: reporting, namespace: nightly}
spec:
  replicas: 1
  selector: {matchLabels: {app: reporting}}
  template:
    metadata: {labels: {app: reporting}}
    spec:
      containers:
        - name: web
          image: registry.lab:5000/lab/labapp:1.4
          resources: {limits: {memory: 256Mi}}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
        - name: report-builder
          image: registry.lab:5000/lab/labapp:1.4
          args: ["--port", "8081"]
          env: [{name: APP_NAME, value: report-builder}]
          resources: {limits: {memory: 192Mi}}
YML
wait_rollout nightly deploy/reporting
p=$(kx -n nightly get pods -l app=reporting -o jsonpath='{.items[0].metadata.name}')
kx -n nightly exec "$p" -c report-builder -- labapp get "http://localhost:8081/alloc?mb=300" >/dev/null 2>&1 || true
oom() { [ "$(kx -n nightly get pod "$p" -o jsonpath='{.status.containerStatuses[?(@.name=="report-builder")].lastState.terminated.reason}')" = OOMKilled ]; }
retry 90 oom || die "report-builder was not OOM-killed"
