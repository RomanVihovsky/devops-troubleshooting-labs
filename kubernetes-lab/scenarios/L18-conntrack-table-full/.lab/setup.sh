# L18: a sysctl.d "tuning" on w3 caps nf_conntrack_max just above the current count (set after kube-proxy started)
kns quotes
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: quotes, namespace: quotes}
spec:
  replicas: 2
  selector: {matchLabels: {app: quotes}}
  template:
    metadata: {labels: {app: quotes}}
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions: [{key: kubernetes.io/hostname, operator: NotIn, values: [k8s-w3]}]
      containers:
        - name: quotes
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: quotes}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 5}
---
apiVersion: v1
kind: Service
metadata: {name: quotes, namespace: quotes}
spec:
  selector: {app: quotes}
  ports: [{port: 8080, targetPort: 8080}]
YML
wait_rollout quotes deploy/quotes
nxi k8s-w3 >/dev/null <<'__X__'
set -eu
c=$(cat /proc/sys/net/netfilter/nf_conntrack_count)
m=$(( (c + 4000) / 1000 * 1000 ))
printf '# HARD-230: limit kernel memory used by connection tracking on small VMs\nnet.netfilter.nf_conntrack_max = %s\n' "$m" > /etc/sysctl.d/80-conntrack.conf
sysctl -q -p /etc/sysctl.d/80-conntrack.conf
__X__
