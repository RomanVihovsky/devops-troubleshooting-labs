# P10 - readiness probe on a path the app doesn't serve

**Root cause**: `readinessProbe.httpGet.path: /healthz` → 404 → the pod never becomes Ready, the
EndpointSlice lists it as not ready, the Service has no ready endpoints → timeouts.

**Diagnosis**: `kubectl get pods` (0/1), `kubectl describe pod` (Readiness probe failed: HTTP probe failed
with statuscode: 404), `kubectl get endpointslices`.

**Fix**: `/ready` (labapp's readiness endpoint).

**Interview notes**
- Not-Ready pods are never restarted - they just get no traffic. "Running 0/1" is always readiness.
- Readiness may check dependencies (the app can't serve without its DB) - liveness must not.
- Rolling updates wait for readiness: a broken readiness probe also blocks every rollout.
