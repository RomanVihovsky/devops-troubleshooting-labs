# The autoscaler did nothing during the load test
**INC-2517** · P2 · Reporter: performance team

`api` (namespace `hpa`, `workspace/R01/api.yaml`) has an HPA for 60% CPU, 1-5 replicas. During yesterday's load
test it stayed at 1 replica while the pod burned CPU; `kubectl -n hpa get hpa` shows `cpu: <unknown>/60%`. Make the
autoscaler work - same target (60% CPU), same range.

**Test**: the HPA reports a CPU utilization; under load (the test generates it for ~2 minutes) it scales `api`
beyond 1 replica; the HPA still targets 60% CPU with 1-5 replicas.
