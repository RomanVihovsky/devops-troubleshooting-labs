# R03 - CPU throttling: low average, high latency

**Root cause**: `limits.cpu: 50m` gives the container a CFS quota of 5 ms per 100 ms period. Each request needs
~20 ms of CPU (PBKDF2 hashing), so it is spread over several periods: ~400 ms of wall time on its own, and
seconds once requests queue. The dashboard averaged CPU over minutes against the **node**: a few percent. The
container was throttled most of the time.

**Diagnosis**
```
kubectl -n quotes get deploy quotes -o jsonpath='{.spec.template.spec.containers[0].resources}'; echo
kubectl -n quotes top pods                                   # pinned at ~50m = the limit
# on the node: cgroup v2 cpu.stat of the container
#   nr_periods / nr_throttled / throttled_usec   (throttled ratio close to 1)
kubectl -n quotes run t --rm -i --image=registry.lab:5000/lab/labapp:1.4 -- labapp load http://quotes:8080/items -c 4 -d 15 --rps 20
```

**Fix**: a realistic limit (`1`) or no CPU limit, and keep a request (the scheduling guarantee).

**Interview notes**
- Requests = guaranteed share (cpu.weight) and scheduling. Limits = a hard cap (cpu.max quota). Many teams
  set CPU requests but **no CPU limits** for latency-sensitive services; memory limits stay (memory isn't
  compressible).
- Throttling shows in `container_cpu_cfs_throttled_periods_total` / `_seconds_total`. Alert on the ratio,
  not on usage.
- Multi-threaded runtimes burn the quota faster: 4 threads × 5 ms = the whole 20 ms quota in 5 ms of wall time.
- Guaranteed QoS needs limits = requests. Use it where predictability matters more than burst (and with the
  static CPU manager for exclusive cores).
