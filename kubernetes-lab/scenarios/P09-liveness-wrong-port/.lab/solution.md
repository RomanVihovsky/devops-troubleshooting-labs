# P09 - liveness probe on the wrong port

**Root cause**: liveness `httpGet` on port 8081, the app listens on 8080. Three failed checks (period 10 s ×
failureThreshold 3) → the kubelet kills the container → restart. Readiness (on the right port) passes in
between, so it looks healthy.

**Diagnosis**: `kubectl describe pod` (Liveness probe failed: ... connect: connection refused; Container
profile failed liveness probe, will be restarted).

**Fix**: the right (named) port.

**Interview notes**
- Liveness = "restart me", readiness = "don't send me traffic", startup = "don't judge me yet" (P11).
- A liveness probe must check the process itself, never dependencies (a DB outage would restart every
  pod). A wrong liveness probe is worse than none.
- Use named ports (`port: http`) so probes follow port changes.
