# B04: volumeClaimTemplates with a missing StorageClass, the password from a key the Secret doesn't have, a
# ClusterIP Service where per-pod DNS needs a headless one; orders waits for postgres-0.postgres
kns orders-db
pw=$(openssl rand -hex 12)
kx -n orders-db create secret generic postgres-auth --from-literal=postgres-password="$pw" --dry-run=client -o yaml | ka -f -
ka -f postgres.yaml
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders, namespace: orders-db}
spec:
  replicas: 1
  selector: {matchLabels: {app: orders}}
  template:
    metadata: {labels: {app: orders}}
    spec:
      containers:
        - name: orders
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: APP_NAME, value: orders}
            - {name: STORAGE_BACKEND, value: postgres}
            - {name: AUTO_MIGRATE, value: "true"}
            - {name: DATABASE_URL, value: "postgres://orders@postgres-0.postgres.orders-db.svc:5432/orders"}
            - {name: DATABASE_PASSWORD_FILE, value: /etc/pg/postgres-password}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          volumeMounts: [{name: pg, mountPath: /etc/pg, readOnly: true}]
      volumes:
        - name: pg
          secret: {secretName: postgres-auth}
YML
pending() { [ "$(kx -n orders-db get pvc data-postgres-0 -o jsonpath='{.status.phase}' 2>/dev/null)" = Pending ]; }
retry 60 pending || die "the PVC is not Pending"
! deploy_ready orders-db orders 1 || die "orders is Ready"
