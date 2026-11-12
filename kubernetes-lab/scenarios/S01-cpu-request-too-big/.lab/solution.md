# S01 - a request no node can satisfy

**Root cause**: `requests.cpu: "16"`; the workers have 2 vCPUs. The scheduler filters every node out.

**Fix**: a realistic request (100m).

**Interview notes**
- Scheduling = requests vs allocatable (capacity minus kube-/system-reserved), not live usage. An idle
  cluster can be "full".
- Requests drive QoS and, with HPA, utilisation percentages; limits are enforced by the kernel.
- `kubectl describe node` → "Allocated resources" shows how full a node is for the scheduler.
