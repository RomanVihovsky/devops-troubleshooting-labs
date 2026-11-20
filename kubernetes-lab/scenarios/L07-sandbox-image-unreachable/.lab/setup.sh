# L07: w2's containerd sandbox (pause) image points at a registry that doesn't exist
nxi k8s-w2 >/dev/null <<'__X__'
set -eu
f=/etc/containerd/config.toml
grep -q "sandbox = 'registry.k8s.io/pause:" "$f"
sed -i "s|sandbox = 'registry.k8s.io/pause:\([^']*\)'|sandbox = 'registry.internal.corp/k8s/pause:\1'   # HARD-224|" "$f"
grep -q registry.internal.corp "$f"
systemctl restart containerd
__X__
retry 120 nodes_ready || die "w2 not Ready after the containerd restart"
kns shipping
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: shipping-api, namespace: shipping}
spec:
  replicas: 2
  selector: {matchLabels: {app: shipping-api}}
  template:
    metadata: {labels: {app: shipping-api}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w2}
      containers:
        - name: api
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: shipping-api}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
sandbox_err() { local o; o=$(kx -n shipping get events --field-selector reason=FailedCreatePodSandBox -o jsonpath='{.items[*].message}' 2>/dev/null) || true; grep -q 'registry.internal.corp' <<<"$o"; }
retry 120 sandbox_err || die "the sandbox image did not fail"
