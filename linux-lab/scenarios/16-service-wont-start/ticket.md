# Service won't start after "a small edit"
**LNX-116** · P1 · Reporter: inventory team

A colleague "tidied up" `/etc/systemd/system/inventory-api.service` before leaving on
holiday. Since then `systemctl start inventory-api` fails immediately. The app code in
`/opt/inventory` is unchanged. It must run as the unprivileged `inventory` user, not root.

**Test**: `inventory-api` is active, `curl localhost:8083/` answers, and the process runs
as user `inventory`.
