# L09: w1's hosts.toml for the lab registry points at port 5050; the image isn't cached there
nxi k8s-w1 >/dev/null <<'__X__'
set -eu
f=/etc/containerd/certs.d/registry.lab:5000/hosts.toml
sed -i 's|registry.lab:5000|registry.lab:5050|g' "$f"
grep -q 5050 "$f"
crictl rmi registry.lab:5000/lab/labapp:1.3 >/dev/null 2>&1 || true
__X__
kns edge
ka -f - <<'YML'
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: edge-cache, namespace: edge}
spec:
  selector: {matchLabels: {app: edge-cache}}
  template:
    metadata: {labels: {app: edge-cache}}
    spec:
      containers:
        - name: cache
          image: registry.lab:5000/lab/labapp:1.3
          env: [{name: APP_NAME, value: edge-cache}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 5}
YML
w1_backoff() { kx -n edge get pods -l app=edge-cache --field-selector spec.nodeName=k8s-w1 -o json \
  | jq -e '[.items[].status.containerStatuses[]?.state.waiting.reason] | map(select(. == "ImagePullBackOff" or . == "ErrImagePull")) | length > 0' >/dev/null; }
retry 180 w1_backoff || die "the w1 pod pulled its image"
