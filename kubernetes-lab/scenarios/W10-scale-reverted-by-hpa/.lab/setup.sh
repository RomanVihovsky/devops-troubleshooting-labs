# W10: an HPA with minReplicas 5 owns api's replicas
kns api
kx -n api create deployment api --image=registry.lab:5000/lab/labapp:1.4 --replicas=5 --dry-run=client -o yaml \
  | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); c = d["spec"]["template"]["spec"]["containers"][0]
c["resources"] = {"requests": {"cpu": "50m", "memory": "64Mi"}}
print(yaml.safe_dump(d))' | ka -f -
ka -f - <<'YML'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: api, namespace: api}
spec:
  scaleTargetRef: {apiVersion: apps/v1, kind: Deployment, name: api}
  minReplicas: 5
  maxReplicas: 10
  metrics:
    - type: Resource
      resource: {name: cpu, target: {type: Utilization, averageUtilization: 70}}
YML
wait_rollout api deploy/api
kx -n api scale deploy/api --replicas=2 >/dev/null
back5() { [ "$(kx -n api get deploy api -o jsonpath='{.spec.replicas}')" = 5 ]; }
retry 90 back5 || die "the HPA did not scale back to 5"
