## Hint 1
`docker service ps --no-trunc app_web` says *unhealthy*. On the node:
`docker inspect -f '{{json .State.Health}}' <cid> | jq` - is the probe failing or timing out?
## Hint 2
Time the endpoint yourself from inside the container:
`docker exec <cid> sh -c 'time wget -qO- localhost:8000/health'`. Then
`docker stats --no-stream`. Busy at a suspiciously round CPU number?
## Hint 3
Read the cgroup: `docker exec <cid> cat /sys/fs/cgroup/cpu.max /sys/fs/cgroup/cpu.stat`.
`nr_throttled` / `throttled_usec` growing = CFS quota throttling. Check `limits.cpus`.
