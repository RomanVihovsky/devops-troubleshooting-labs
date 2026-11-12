# R04: w2's kubelet hard eviction threshold for memory.available just above what the node has free (measured while
# batch-cache holds its 600 MiB, so batch-cache is evicted first)
kns payments
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: payments-api, namespace: payments}
spec:
  replicas: 2
  selector: {matchLabels: {app: payments-api}}
  template:
    metadata: {labels: {app: payments-api}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w2}
      containers:
        - name: api
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: CACHE_MB, value: "64"}]
          resources: {requests: {cpu: 50m, memory: 64Mi}, limits: {memory: 256Mi}}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 5}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: batch-cache, namespace: payments}
spec:
  replicas: 1
  selector: {matchLabels: {app: batch-cache}}
  template:
    metadata: {labels: {app: batch-cache}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w2}
      containers:
        - name: cache
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: CACHE_MB, value: "600"}]      # BestEffort + the most memory: the kubelet's first victim
YML
wait_rollout payments deploy/payments-api; wait_rollout payments deploy/batch-cache
avail=$(kx get --raw /api/v1/nodes/k8s-w2/proxy/stats/summary | jq '.node.memory.availableBytes / 1048576 | floor')
thr="$(( (avail + 300) / 100 * 100 ))Mi"
remember r04_threshold "$thr"
nxi k8s-w2 >/dev/null <<__X__
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d["evictionHard"] = {"memory.available": "$thr"}
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
evicted() { kx -n payments get events -o jsonpath='{.items[*].message}' 2>/dev/null | grep -q 'low on resource: memory'; }
retry 240 evicted || die "nothing was evicted"
