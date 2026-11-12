# W12: PDB minAvailable 3 for 3 replicas (0 disruptions allowed); the drain was attempted and left w1 cordoned
kns ha
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: ha-api, namespace: ha}
spec:
  replicas: 3
  selector: {matchLabels: {app: ha-api}}
  template:
    metadata: {labels: {app: ha-api}}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - {labelSelector: {matchLabels: {app: ha-api}}, topologyKey: kubernetes.io/hostname}
      containers:
        - name: api
          image: registry.lab:5000/lab/labapp:1.4
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: ha-api, namespace: ha}
spec:
  minAvailable: 3
  selector: {matchLabels: {app: ha-api}}
YML
wait_rollout ha deploy/ha-api
w1pod=$(kx -n ha get pods -l app=ha-api --field-selector spec.nodeName=k8s-w1 -o jsonpath='{.items[0].metadata.name}')
[ -n "$w1pod" ] || die "no ha-api pod on k8s-w1"
remember w12_pod "$w1pod"
kx drain k8s-w1 --ignore-daemonsets --delete-emptydir-data --timeout=30s >/dev/null 2>&1 && die "the drain succeeded"
[ "$(kx get node k8s-w1 -o jsonpath='{.spec.unschedulable}')" = true ] || die "k8s-w1 is not cordoned"
