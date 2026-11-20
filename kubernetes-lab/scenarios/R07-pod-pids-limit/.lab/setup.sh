# R07: w1's kubelet podPidsLimit 64; reports-api (pinned to w1) starts 100 threads
nxi k8s-w1 >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d["podPidsLimit"] = 64        # HARD-217: fork-bomb protection
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
retry 120 nodes_ready || die "w1 not Ready after the kubelet restart"
kns reports
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: reports-api, namespace: reports}
spec:
  replicas: 2
  selector: {matchLabels: {app: reports-api}}
  template:
    metadata: {labels: {app: reports-api}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w1}
      containers:
        - name: api
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: APP_NAME, value: reports-api}
            - {name: WORKER_THREADS, value: "100"}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
YML
thread_err() { local o; o=$(kx -n reports logs deploy/reports-api --tail=20 2>/dev/null) || true; grep -q "can't start new thread" <<<"$o"; }
retry 120 thread_err || die "reports-api never hit the pids limit"
