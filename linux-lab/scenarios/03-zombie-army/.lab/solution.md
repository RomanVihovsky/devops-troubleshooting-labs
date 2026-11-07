# Solution - a parent that never reaps its children

**Root cause**: `report-worker` forks a child per job but - because of
`reap_children = no` in `/etc/report-worker.conf` - never calls `wait()` and doesn't
ignore SIGCHLD. Every exited child stays a **zombie** (state `Z`, `<defunct>`): it holds only
a PID and its exit status, waiting for the parent to collect it.

**Diagnose**
```
ps -eo pid,ppid,state,cmd | awk '$3=="Z"' | head      # all share one PPID
ps -o pid,cmd -p <ppid>                                # python3 /opt/report-worker/worker.py
systemctl status <ppid>                                # -> report-worker.service
cat /etc/report-worker.conf
```

**Fix**: `reap_children = yes`, then `systemctl restart report-worker`. When the old
parent exits, its zombies are re-parented to PID 1 (systemd), which reaps them at once.

**Interview notes**: you cannot kill a zombie - it's already dead. Fix or restart the
**parent**. Zombies cost no CPU/RAM, but each holds a PID: enough of them exhaust
`pid_max` / the cgroup `pids.max` and `fork()` starts failing. Containers without a real
init as PID 1 collect zombies the same way (use `--init`, tini).
