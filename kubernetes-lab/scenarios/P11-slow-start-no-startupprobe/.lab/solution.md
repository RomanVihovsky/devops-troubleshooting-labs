# P11 - slow start without a startupProbe

**Root cause**: the app opens its port after 45 s; liveness starts at 10 s and kills after 3 × 5 s. Every
start is killed before it finishes: an endless restart loop (CrashLoopBackOff with exit 137/143).

**Fix**: a `startupProbe` (failureThreshold × period ≥ the worst start time). Until it succeeds, liveness
and readiness are disabled; afterwards liveness keeps its tight settings.

**Interview notes**
- Before startup probes people raised `initialDelaySeconds` - which delays hang detection on *every* start
  and still breaks when the start gets slower.
- `kubectl describe` shows "Liveness probe failed ... connection refused" during start - the app isn't
  broken, the probe is impatient.
- Long starts also slow rollouts and autoscaling; consider lazy loading.
