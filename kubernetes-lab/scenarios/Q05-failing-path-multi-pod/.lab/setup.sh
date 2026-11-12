# Q05: 6 replicas, 30% of GET /items fail (500, logged); a client keeps calling a mix of paths
kns edge
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: edge, namespace: edge}
spec:
  replicas: 6
  selector: {matchLabels: {app: edge}}
  template:
    metadata: {labels: {app: edge}}
    spec:
      containers:
        - name: edge
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: edge}, {name: ERROR_RATE, value: "0.3"}]
          resources: {requests: {cpu: 20m, memory: 48Mi}}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 5}
---
apiVersion: v1
kind: Service
metadata: {name: edge, namespace: edge}
spec: {selector: {app: edge}, ports: [{port: 8080}]}
---
apiVersion: v1
kind: Pod
metadata: {name: traffic, namespace: edge, labels: {app: traffic}}
spec:
  containers:
    - name: client
      image: docker.io/library/busybox:1.37
      command: ["sh", "-c", "while true; do for p in / /version /items /config /health; do wget -q -O /dev/null -T 3 http://edge.edge.svc.cluster.local:8080$p; done; sleep 1; done"]
YML
wait_rollout edge deploy/edge 180
# capture first: setup runs with pipefail, and grep -q exiting early SIGPIPEs kubectl (exit 141)
errors() { local o; o=$(kx -n edge logs -l app=edge --tail=200 2>/dev/null) || true; grep -q ' 500 ' <<<"$o"; }
retry 120 errors || die "no 500s logged"
