kns edge
ka -f - <<'YML'
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: node-probe, namespace: edge}
spec:
  selector: {matchLabels: {app: node-probe}}
  template:
    metadata: {labels: {app: node-probe}}
    spec:
      containers:
        - name: probe
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: node-probe}]
          ports: [{containerPort: 8080, hostPort: 9100}]
          resources: {requests: {cpu: 10m, memory: 32Mi}}
YML
kx -n edge rollout status ds/node-probe --timeout=180s >/dev/null
ka -f edge-proxy.yaml
pending() { [ "$(kx -n edge get pods -l app=edge-proxy --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
