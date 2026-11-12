# C05: the ConfigMap was created in "default" (no namespace in the file); the pods in checkout can't see it
kns checkout
ka -f - <<YML
$(sed 's/^  name: app-config$/  name: app-config\n  namespace: default/' app-config.yaml)
YML
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: checkout, namespace: checkout}
spec:
  replicas: 2
  selector: {matchLabels: {app: checkout}}
  template:
    metadata: {labels: {app: checkout}}
    spec:
      containers:
        - name: checkout
          image: registry.lab:5000/lab/labapp:1.4
          envFrom: [{configMapRef: {name: app-config}}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
cce() { kx -n checkout get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -q CreateContainerConfigError; }
retry 120 cce || die "no CreateContainerConfigError"
