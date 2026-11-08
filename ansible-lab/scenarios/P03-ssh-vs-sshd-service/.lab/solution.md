# Solution - service names differ per OS (and a lost handler)

**Root cause**: the handler restarts `ssh` - Debian's unit name. On Rocky the unit is `sshd`, so the handler
failed. The failed run dropped the notification (see R01); later runs found the drop-in unchanged and never
restarted sshd on web2 - green runs, no banner.

**Fix**: `sshd_banner_service` from `vars/<os_family>.yml`; `reloaded` is enough for sshd config; reload web2's
sshd once by hand.

**Interview notes**
* Same trap: `cron`/`crond`, `apache2`/`httpd`, `ssh`/`sshd`, `syslog` group `adm`/`root`.
* Drop-ins (`sshd_config.d/`) are included first on both Debian 12 and EL9 - the first value wins.
* `sshd -T` shows the effective config; `sshd -t` validates before reload.
