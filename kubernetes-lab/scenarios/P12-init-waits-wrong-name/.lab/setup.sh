kns orders-db
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: postgresql, namespace: orders-db}
spec:
  replicas: 1
  selector: {matchLabels: {app: postgresql}}
  template:
    metadata: {labels: {app: postgresql}}
    spec:
      containers:
        - {name: db, image: registry.lab:5000/lab/labapp:1.4, env: [{name: APP_NAME, value: fake-postgres}]}
---
apiVersion: v1
kind: Service
metadata: {name: postgresql, namespace: orders-db}
spec:
  selector: {app: postgresql}
  ports: [{port: 5432, targetPort: 8080}]
YML
ka -f orders-api.yaml
sleep 20
[ "$(kx -n orders-db get pods -l app=orders-api -o jsonpath='{.items[0].status.phase}')" = Pending ] || die "orders-api got past init"
