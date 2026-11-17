# X05: namespaceSelector and podSelector as two "from" items = OR (all of monitoring + app=prometheus in db)
kns db monitoring
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders-db, namespace: db}
spec:
  replicas: 1
  selector: {matchLabels: {app: orders-db}}
  template:
    metadata: {labels: {app: orders-db}}
    spec:
      containers:
        - name: db
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: orders-db}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
---
apiVersion: v1
kind: Service
metadata: {name: orders-db, namespace: db}
spec:
  selector: {app: orders-db}
  ports: [{port: 5432, targetPort: 8080}]
YML
wait_rollout db deploy/orders-db
ka -f allow-prometheus.yaml
tcp_ok_as monitoring - orders-db.db.svc:5432 || die "the OR hole is not open"
