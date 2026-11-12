# C03: cart's Secret has the password base64-encoded TWICE under data: (the API decodes only once)
kns cart
pw="rds-$(openssl rand -hex 8)"
remember c03_pw "$pw"
kx -n cart create secret generic redis-auth --from-literal=password="$pw" --dry-run=client -o yaml | ka -f -
twice=$(printf %s "$pw" | base64 -w0 | base64 -w0)
cat > cart-secret.yaml <<YML
# cart's own copy of the Redis password (base64, as the docs say)
apiVersion: v1
kind: Secret
metadata: {name: cart-redis, namespace: cart}
type: Opaque
data:
  password: $twice
YML
ka -f cart-secret.yaml
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: redis, namespace: cart}
spec:
  replicas: 1
  selector: {matchLabels: {app: redis}}
  template:
    metadata: {labels: {app: redis}}
    spec:
      containers:
        - name: redis
          image: registry.lab:5000/lab/redis:7-alpine
          args: ["--requirepass", "$(REDIS_PASSWORD)"]
          env: [{name: REDIS_PASSWORD, valueFrom: {secretKeyRef: {name: redis-auth, key: password}}}]
          readinessProbe: {tcpSocket: {port: 6379}, periodSeconds: 3}
---
apiVersion: v1
kind: Service
metadata: {name: redis, namespace: cart}
spec: {selector: {app: redis}, ports: [{port: 6379}]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: cart, namespace: cart}
spec:
  replicas: 2
  selector: {matchLabels: {app: cart}}
  template:
    metadata: {labels: {app: cart}}
    spec:
      containers:
        - name: cart
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: REDIS_HOST, value: redis}
            - {name: REDIS_PORT, value: "6379"}
            - name: REDIS_PASSWORD
              valueFrom: {secretKeyRef: {name: cart-redis, key: password}}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
wait_rollout cart deploy/redis
wrongpass() { kx -n cart logs deploy/cart 2>/dev/null | grep -q WRONGPASS; }
retry 120 wrongpass || die "cart did not fail with WRONGPASS"
