# Solution - CPU quota throttling makes the healthcheck time out

**Root cause**: `limits.cpus: "0.02"` = CFS quota of 2 ms CPU per 100 ms period.
The `/health` self-test needs ~25 ms of CPU -> 1-2 s wall time when throttled;
Python startup alone takes ~30 s. The healthcheck `timeout: 2s` fails three
times -> unhealthy -> SIGKILL -> replaced. "Idles at 1%" was an *average*; limits
must fit *peaks*.

**Diagnose** (on the node running a task)
```
docker stats --no-stream                      # CPU pinned at ~2.00%
docker exec <cid> cat /sys/fs/cgroup/cpu.max  # "2000 100000"
docker exec <cid> cat /sys/fs/cgroup/cpu.stat # nr_throttled ~ nr_periods, throttled_usec huge
docker inspect -f '{{json .State.Health}}' <cid> | jq '.Log[-1]'   # "Health check exceeded timeout"
```

**Fix**: give it a sane limit (e.g. `cpus: "0.5"`) - or no limit plus a reservation.

**Real-world notes**: CPU throttling causes tail latency long before CPU graphs
look "full" - averages hide 100 ms bursts. Multi-threaded runtimes burn quota
on all cores in parallel and get throttled even faster.
