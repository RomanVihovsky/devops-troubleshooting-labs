# Y10: .sops.yaml "tightened" to ^data$; the new Secret uses stringData, so sops leaves it in plain text. The
# password is live in newsvc's Redis.
pw="leak-$(openssl rand -hex 6)"
remember y10_leaked "$pw"
export SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" PW=$pw
gitops_commit "sops: only data is secret (stringData is for config)" "dev-bob" <<'SNIP'
sed -i -E 's/^(\s*encrypted_regex: ).*/\1^data$/' .sops.yaml
SNIP
gitops_commit "new-service: redis password" "dev-bob" <<'SNIP'
mkdir -p secrets
printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: redis-auth\n  namespace: newsvc\ntype: Opaque\nstringData:\n  password: %s\n' "$PW" > secrets/new-service.enc.yaml
sops -e -i secrets/new-service.enc.yaml
grep -q "$PW" secrets/new-service.enc.yaml
SNIP
kns newsvc
kx -n newsvc create secret generic redis-auth --from-literal=password="$pw" --dry-run=client -o yaml | ka -f -
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: redis, namespace: newsvc}
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
          env:
            - name: REDIS_PASSWORD
              valueFrom: {secretKeyRef: {name: redis-auth, key: password}}
          readinessProbe: {tcpSocket: {port: 6379}, periodSeconds: 5}
---
apiVersion: v1
kind: Service
metadata: {name: redis, namespace: newsvc}
spec:
  selector: {app: redis}
  ports: [{port: 6379}]
YML
wait_rollout newsvc deploy/redis
