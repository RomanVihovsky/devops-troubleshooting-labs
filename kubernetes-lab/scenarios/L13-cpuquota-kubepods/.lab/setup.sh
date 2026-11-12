# L13: a persistent CPUQuota of 20 % on kubepods.slice of k8s-w1 - every pod there shares one fifth of a CPU
kns search
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: search, namespace: search}
spec:
  replicas: 2
  selector: {matchLabels: {app: search}}
  template:
    metadata: {labels: {app: search}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w1}
      containers:
        - name: search
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: HASH_ITERATIONS, value: "200000"}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3, timeoutSeconds: 1}
          livenessProbe: {httpGet: {path: /health, port: 8080}, periodSeconds: 5, timeoutSeconds: 1, failureThreshold: 3}
YML
wait_rollout search deploy/search
nx k8s-w1 'systemctl set-property kubepods.slice CPUQuota=20%' </dev/null
capped() { nx k8s-w1 'cat /sys/fs/cgroup/kubepods.slice/cpu.max' </dev/null | grep -q '^20000 '; }
retry 30 capped || die "kubepods.slice not capped"
