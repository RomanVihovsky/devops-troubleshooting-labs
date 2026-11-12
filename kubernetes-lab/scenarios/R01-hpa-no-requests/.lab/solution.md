# R01 - utilization needs a request

**Root cause**: the HPA scales on CPU **utilization** = usage ÷ request. `api`'s container had no CPU request,
so the HPA couldn't compute a percentage: `ScalingActive=False, FailedGetResourceMetric: missing request for
cpu`, shown as `<unknown>/60%`. With no metric the HPA doesn't scale at all, in either direction.

**Diagnosis**
```
kubectl -n hpa get hpa api                    # cpu: <unknown>/60%
kubectl -n hpa describe hpa api | grep -A3 -i 'missing request'
kubectl -n hpa top pods                       # metrics-server is fine
```

**Fix**: a CPU request on every container of the pod (e.g. `100m`). Then 60% means 60m per pod.

**Interview notes**
- Every container counts: a sidecar without a request breaks utilization for the whole pod (or use
  `ContainerResource` metrics for one container).
- Choosing the request matters twice: for scheduling and as the HPA's 100%. A too-small request makes the HPA
  scale aggressively, a too-big one never.
- `AverageValue` targets (e.g. `500m` per pod) work without requests. Custom/external metrics (RPS, queue
  depth via KEDA/Prometheus Adapter) often scale web apps better than CPU.
