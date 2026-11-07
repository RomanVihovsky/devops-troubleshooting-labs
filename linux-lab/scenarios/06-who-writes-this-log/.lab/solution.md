# Solution - find the writer with lsof, trace it to its unit

**Root cause**: `systemd-telemetry.service` (a misleading name - it is not part of
systemd) runs `/usr/lib/systemd-telemetry/telemetryd`, which appends a line per second.
It has `Restart=always`, so `kill` brings it back after 1 s, and it is enabled at boot.

**Diagnose**
```
sudo lsof /var/log/app/events.log           # COMMAND telemetryd / bash, PID
sudo fuser -v /var/log/app/events.log
systemctl status <pid>                      # -> systemd-telemetry.service
ls -l /proc/<pid>/exe; tr '\0' ' ' < /proc/<pid>/cmdline
```

**Fix**: `sudo systemctl disable --now systemd-telemetry` (optionally `mask` it).
Keep the log for the security team.

**Interview notes**: `lsof +D /dir`, `lsof -p <pid>`, `fuser -m /mount` (who blocks
umount), `inotifywait -m`, `auditctl -w <file> -p wa` (who *will* write). Always find what
*starts* a process before you kill it: systemd unit, cron, parent shell, container.
