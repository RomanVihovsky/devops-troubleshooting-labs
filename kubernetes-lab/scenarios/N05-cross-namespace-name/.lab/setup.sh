kns storefront inventory-api
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: api, namespace: inventory-api}
spec:
  replicas: 2
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
        - name: app
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: api}]
          ports: [{name: http, containerPort: 8080}]
          readinessProbe: {httpGet: {path: /ready, port: http}, periodSeconds: 3}
---
apiVersion: v1
kind: Service
metadata: {name: api, namespace: inventory-api}
spec:
  selector: {app: api}
  ports: [{name: http, port: 80, targetPort: http}]
YML
ka -f storefront.yaml
wait_rollout inventory-api deploy/api
wait_rollout storefront deploy/storefront
remember n05_api "$(kx -n inventory-api get deploy,svc -o json | jq -c '[.items[] | {k: .kind, n: .metadata.name, s: .spec.selector}]')"
