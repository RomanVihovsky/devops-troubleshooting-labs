# Solution - memory.high throttling puts tasks in D state

**Root cause**: `thumbnailer.service` has `MemoryHigh=48M`, but its 4 workers need
~4 x 25 MB. cgroup v2 `memory.high` is a *soft* limit: it never kills, it **throttles** -
every allocation over the limit triggers reclaim and a penalty sleep in
`mem_cgroup_handle_over_high`. There is no swap, so nothing can be reclaimed, and the
workers spend almost all their time sleeping in **D state**. Linux counts D-state tasks in
the load average: load goes up, CPU stays idle, no OOM, no error message.

**Diagnose**
```
ps -eo state,pid,wchan:32,cmd | awk '$1 ~ /D/'   # wchan: mem_cgroup_handle_over_high
systemctl status <pid>                            # -> thumbnailer.service
systemctl show -p MemoryHigh,MemoryCurrent thumbnailer
cat /sys/fs/cgroup/system.slice/thumbnailer.service/memory.events   # high <growing>
cat /sys/fs/cgroup/system.slice/thumbnailer.service/memory.pressure  # PSI: some/full avg
```

**Fix**: give it a realistic budget, persistently:
```
sudo systemctl set-property thumbnailer.service MemoryHigh=256M   # writes a drop-in
sudo systemctl restart thumbnailer
```
(or `systemctl edit thumbnailer` -> `[Service] MemoryHigh=256M`).

**Interview notes**: "high load, idle CPU" = tasks in D state. Classic causes: slow or
saturated disks (look at `vmstat` `wa`/`b`, `iostat -x`, `pidstat -d`), hung NFS mounts,
and - on cgroup v2 systems (systemd, Kubernetes) - memory.high throttling. PSI files in
`/proc/pressure/` tell you which resource tasks are stalled on.

*Lab note*: the lab deliberately does not throttle real disks - capping I/O on the host's
root disk can stall the host filesystem journal and freeze the whole machine.
