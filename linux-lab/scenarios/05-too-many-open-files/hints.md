## Hint 1
`journalctl -u catalog-api` for the error. Then: what limit does the **running process**
actually have? `cat /proc/<pid>/limits` (grab a PID quickly, it restarts) - not your shell's `ulimit`.
## Hint 2
`/etc/security/limits.conf` is applied by PAM at **login** (ssh, su, sudo). systemd
services never log in. Where do services get their limits from? `systemctl show -p LimitNOFILE catalog-api`.
## Hint 3
`systemctl cat catalog-api` - including drop-ins. Set `LimitNOFILE=` in a drop-in
(`systemctl edit catalog-api`), then `daemon-reload` + restart.
