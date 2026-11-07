# Solution - systemd services ignore limits.conf

**Root cause**: a hardening drop-in sets `LimitNOFILE=256`; the API opens 300 shard files at
startup and dies with EMFILE. The colleague's change to `/etc/security/limits.conf` only
affects **PAM login sessions** (ssh, su, sudo) - services started by systemd never go
through PAM, so it has no effect on them.

**Diagnose**
```
journalctl -u catalog-api -n 20          # OSError: [Errno 24] Too many open files
systemctl show -p LimitNOFILE catalog-api
cat /proc/$(systemctl show -p MainPID --value catalog-api)/limits | grep 'open files'
systemctl cat catalog-api                # shows the drop-in hardening.conf
ls /proc/<pid>/fd | wc -l                # how many it actually uses
```

**Fix**
```
sudo systemctl edit catalog-api          # [Service]\nLimitNOFILE=65535
sudo systemctl daemon-reload && sudo systemctl restart catalog-api
```
(Drop-ins are applied in lexical order - a later file wins over `hardening.conf`.)

**Interview notes**: three places limits come from - systemd unit (`LimitNOFILE`),
PAM `limits.conf` (login sessions), and the parent process (`ulimit` is inherited). The
system-wide ceiling is `fs.file-max` / `fs.nr_open`. Check the *process*, not your shell.
