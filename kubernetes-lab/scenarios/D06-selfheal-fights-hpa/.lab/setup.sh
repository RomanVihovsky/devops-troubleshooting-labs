# D06: an HPA made by hand (min 3) on demo, whose chart renders replicas: 2 - with self-heal on, they fight
t0=$(date -u +%FT%TZ)
ka -f - <<'YML'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: demo, namespace: demo}
spec:
  scaleTargetRef: {apiVersion: apps/v1, kind: Deployment, name: demo}
  minReplicas: 3
  maxReplicas: 6
  metrics:
    - type: Resource
      resource: {name: cpu, target: {type: Utilization, averageUtilization: 60}}
YML
# self-heal has started reverting the HPA's replica count
healed() { [ "$(kx -n argocd get application demo -o jsonpath='{.status.operationState.startedAt}')" \> "$t0" ]; }
retry 180 healed || die "Argo CD never reverted the HPA"
