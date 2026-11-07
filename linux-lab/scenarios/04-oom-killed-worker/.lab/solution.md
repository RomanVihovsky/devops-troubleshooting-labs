# Solution - cgroup OOM kill from an unbounded cache

**Root cause**: `CACHE_MAX_ITEMS=0` (unlimited) in `/etc/default/data-indexer`: the
indexer caches 1 MiB segments forever. Once the service's cgroup reaches
`MemoryMax=96M`, the kernel's OOM killer kills it (SIGKILL - no chance to log), and
`Restart=always` brings it back to repeat the cycle.

**Diagnose**
```
systemctl status data-indexer          # "Failed with result 'oom-kill'", status=9/KILL
journalctl -u data-indexer | grep -i oom   # "A process of this unit has been killed by the OOM killer"
systemctl show -p MemoryMax,MemoryCurrent,NRestarts data-indexer
cat /sys/fs/cgroup/system.slice/data-indexer.service/memory.events   # oom_kill N
systemctl cat data-indexer             # EnvironmentFile=/etc/default/data-indexer
```
(On a real host also `dmesg -T | grep -i -A5 oom` / `journalctl -k`.)

**Fix**: `CACHE_MAX_ITEMS=50` in `/etc/default/data-indexer`, `systemctl restart data-indexer`.

**Interview notes**: global OOM (whole machine out of memory, victim chosen by
`oom_score`) vs cgroup OOM (one service over its limit, victim inside that cgroup). Exit
code 137 / SIGKILL with no logs is the classic fingerprint. `oom_score_adj` protects
critical processes. Raising the limit hides a leak - it doesn't fix it.
