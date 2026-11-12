# N10: Service db has no selector; its hand-made EndpointSlice points at the old database, which is now off
kns legacy
pw=$(rand); remember n10_pw "$pw"
kx -n legacy create secret generic pg --from-literal=password="$pw" --dry-run=client -o yaml | ka -f -
for n in pg-old pg-new; do
  ka -f - <<YML
apiVersion: apps/v1
kind: Deployment
metadata: {name: $n, namespace: legacy}
spec:
  replicas: 1
  selector: {matchLabels: {app: $n}}
  template:
    metadata: {labels: {app: $n}}
    spec:
      containers:
        - name: postgres
          image: registry.lab:5000/lab/postgres:16-alpine
          env:
            - {name: POSTGRES_USER, value: orders}
            - {name: POSTGRES_DB, value: orders}
            - name: POSTGRES_PASSWORD
              valueFrom: {secretKeyRef: {name: pg, key: password}}
          readinessProbe: {exec: {command: [pg_isready, -U, orders]}, periodSeconds: 3}
YML
done
wait_rollout legacy deploy/pg-old; wait_rollout legacy deploy/pg-new
old_ip=$(kx -n legacy get pods -l app=pg-old -o jsonpath='{.items[0].status.podIP}')
cat > db.yaml <<YML
# db: the orders database - a Service without a selector, pointed at the DB host by hand
apiVersion: v1
kind: Service
metadata: {name: db, namespace: legacy}
spec:
  ports: [{name: postgres, port: 5432, targetPort: 5432}]
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: db-manual
  namespace: legacy
  labels: {kubernetes.io/service-name: db}
addressType: IPv4
ports: [{name: postgres, port: 5432, protocol: TCP}]
endpoints:
  - addresses: ["$old_ip"]
YML
ka -f db.yaml
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders, namespace: legacy}
spec:
  replicas: 2
  selector: {matchLabels: {app: orders}}
  template:
    metadata: {labels: {app: orders}}
    spec:
      containers:
        - name: orders
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: STORAGE_BACKEND, value: postgres}
            - {name: AUTO_MIGRATE, value: "true"}
            - {name: DATABASE_URL, value: "postgres://orders@db:5432/orders"}
            - name: DATABASE_PASSWORD
              valueFrom: {secretKeyRef: {name: pg, key: password}}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
wait_rollout legacy deploy/orders 180
# the migration night: the old database goes off
kx -n legacy scale deploy/pg-old --replicas=0 >/dev/null
unready() { [ "$(kx -n legacy get deploy orders -o jsonpath='{.status.readyReplicas}')" != 2 ]; }
retry 120 unready || die "orders still Ready without its database"
