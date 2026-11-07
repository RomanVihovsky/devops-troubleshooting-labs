# Solution - a cron job respawns a disguised process

**Root cause**: `/usr/local/bin/metrics-agent` runs `python3` with `argv[0]` set to
`[kmetricsd]` (looks like a kernel thread in `ps`). Root's crontab restarts it every
minute if it isn't running, so `kill` only buys you < 60 s.

**Diagnose**
```
top                                   # press c: [kmetricsd]; COMMAND column says python3
ps -o pid,ppid,cmd -p <pid>           # PPID is 1, not 2 -> not a kernel thread
ls -l /proc/<pid>/exe                 # -> /usr/bin/python3.11 (kernel threads have none)
cat /proc/<pid>/cgroup                # /system.slice/cron.service -> started by cron
sudo crontab -l                       # the respawn line
```

**Fix**
```
sudo crontab -e        # delete the metrics-agent line
sudo pkill -f kmetricsd
```

**Interview notes**: also check `/etc/cron.d`, `/etc/cron.{hourly,daily}`, user crontabs
(`/var/spool/cron/crontabs/*`), `systemctl list-timers`, `@reboot` entries, and systemd
units with `Restart=always`. `pstree -p`, `systemd-cgls` and `/proc/<pid>/cgroup` answer
"who started this?" fastest.
