# O07: on w2 - an emptyDir pod (cache), a DaemonSet pod (node-agent), a bare pod (scratch)
kns maint
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: cache, namespace: maint}
spec:
  replicas: 2
  selector: {matchLabels: {app: cache}}
  template:
    metadata: {labels: {app: cache}}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - {labelSelector: {matchLabels: {app: cache}}, topologyKey: kubernetes.io/hostname}
      containers:
        - name: cache
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: CACHE_DIR, value: /scratch}, {name: DISK_CACHE_MB, value: "8"}]
          volumeMounts: [{name: scratch, mountPath: /scratch}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
      volumes: [{name: scratch, emptyDir: {}}]
---
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: node-agent, namespace: maint}
spec:
  selector: {matchLabels: {app: node-agent}}
  template:
    metadata: {labels: {app: node-agent}}
    spec:
      containers:
        - name: agent
          image: docker.io/library/busybox:1.37
          command: ["sh", "-c", "while true; do sleep 3600; done"]
---
apiVersion: v1
kind: Pod
metadata: {name: scratch, namespace: maint}
spec:
  nodeName: k8s-w2
  containers:
    - name: debug
      image: docker.io/library/busybox:1.37
      command: ["sh", "-c", "while true; do sleep 3600; done"]
YML
wait_rollout maint deploy/cache
cachepod=$(kx -n maint get pods -l app=cache --field-selector spec.nodeName=k8s-w2 -o jsonpath='{.items[0].metadata.name}')
if [ -z "$cachepod" ]; then   # make sure one cache pod lands on w2
  kx -n maint delete pod -l app=cache --field-selector spec.nodeName=k8s-w1 --wait=false >/dev/null 2>&1
  w2() { [ -n "$(kx -n maint get pods -l app=cache --field-selector spec.nodeName=k8s-w2 -o name)" ]; }
  retry 60 w2 || true
  cachepod=$(kx -n maint get pods -l app=cache --field-selector spec.nodeName=k8s-w2 -o jsonpath='{.items[0].metadata.name}')
fi
[ -n "$cachepod" ] || die "no cache pod on k8s-w2"
remember o07_cache "$cachepod"
retry 60 kx -n maint wait --for=condition=Ready pod/scratch --timeout=5s || die "scratch not running"
kx drain k8s-w2 --timeout=20s >/dev/null 2>&1 && die "the plain drain succeeded"
kx uncordon k8s-w2 >/dev/null
