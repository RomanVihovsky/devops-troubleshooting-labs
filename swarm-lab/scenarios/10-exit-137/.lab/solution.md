# Solution - container OOM-killed by its cgroup memory limit

**Root cause**: `limits.memory: 128M` but the app allocates a 192 MiB cache (plus
~15 MiB for Python). The cgroup hits `memory.max`, the kernel OOM killer kills the
process (SIGKILL -> exit 137), swarm restarts it, forever.

**Diagnose** (on the node that ran the task)
```
docker ps -a --filter label=com.docker.swarm.service.name=app_web
docker inspect -f 'OOMKilled={{.State.OOMKilled}} limit={{.HostConfig.Memory}}' <cid>
dmesg -T | grep -i "killed process"           # kernel log
cat /sys/fs/cgroup/.../memory.events          # oom_kill counter (inside: /sys/fs/cgroup/memory.events)
docker stats --no-stream                      # live usage vs limit
```

**Fix**: raise the limit with headroom (`memory: 384M`) - or reduce the cache if the
requirement allows it. Keep `reservations` <= `limits`.

**Real-world notes**: JVM/Node/Go runtimes size heaps from the *host* memory
unless told about the cgroup limit (`-XX:MaxRAMPercentage`, `--max-old-space-size`,
`GOMEMLIMIT`). Exit 137 without `OOMKilled=true` means someone else sent SIGKILL
(healthcheck failure, `docker stop` timeout, manual kill).
