# P08 - memory limit below the working set

**Root cause**: the cache allocates 192 MiB (really resident) plus the Python runtime; the limit is 128 Mi.
The kernel's cgroup OOM killer kills the process: exit 137 (128 + SIGKILL), Reason OOMKilled.

**Diagnosis**: `kubectl describe pod` (Last State: Terminated, Reason OOMKilled, Exit Code 137),
`kubectl top pod`, the container's limits.

**Fix**: a limit above the real working set (and a matching request, so the scheduler places it fairly).

**Interview notes**
- Memory is not compressible: over the limit = killed (CPU over the limit = throttled).
- OOMKilled in the container vs node-level eviction (MemoryPressure, pod Evicted) - different signals.
- Requests = scheduling + QoS class; limits = enforcement. `requests == limits` → Guaranteed QoS, last to be
  evicted.
