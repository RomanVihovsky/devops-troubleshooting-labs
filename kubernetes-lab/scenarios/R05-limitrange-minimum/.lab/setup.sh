# R05: a LimitRange with min cpu 200m per container; the Deployment requests 100m
kns team-b
ka -f - <<'YML'
apiVersion: v1
kind: LimitRange
metadata: {name: standard, namespace: team-b}
spec:
  limits:
    - type: Container
      min: {cpu: 200m, memory: 64Mi}
      max: {cpu: "1", memory: 1Gi}
      default: {cpu: 500m, memory: 256Mi}
      defaultRequest: {cpu: 200m, memory: 128Mi}
YML
ka -f worker.yaml
rejected() { kx -n team-b get events -o jsonpath='{.items[*].message}' | grep -q 'minimum cpu usage per Container'; }
retry 60 rejected || die "the pods were not rejected"
remember r05_lr "$(kx -n team-b get limitrange standard -o jsonpath='{.spec}')"
