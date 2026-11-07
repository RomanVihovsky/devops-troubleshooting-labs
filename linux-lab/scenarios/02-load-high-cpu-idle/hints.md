## Hint 1
Linux load average counts runnable **and** uninterruptible (state `D`) tasks. Which
processes are in D state? `ps -eo state,pid,ppid,wchan:32,cmd | awk '$1 ~ /D/'`
## Hint 2
D usually means "waiting for I/O" - but not always. Where in the kernel are they
sleeping (the `wchan` column, `cat /proc/<pid>/wchan`)? Which unit owns them (`systemctl status <pid>`)?
Compare `/proc/pressure/cpu`, `/proc/pressure/io`, `/proc/pressure/memory`.
## Hint 3
cgroup v2 `memory.high` doesn't kill - it **throttles**: tasks over the limit are put to
sleep in reclaim. Look at the unit's memory settings and counters:
`systemctl show -p MemoryHigh,MemoryMax,MemoryCurrent thumbnailer` and
`/sys/fs/cgroup/system.slice/thumbnailer.service/memory.events` (`high` counter).
