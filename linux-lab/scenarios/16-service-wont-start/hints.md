## Hint 1
`systemctl status inventory-api` - read the `code=`/`status=` part. systemd exit statuses
2xx are *its* errors, before your program even ran (`man systemd.exec`, "Process Exit Codes").
## Hint 2
`journalctl -u inventory-api -n 20`, `systemctl cat inventory-api`. Check every name and
path in the unit actually exists (`id`, `ls`).
## Hint 3
There may be more than one mistake - fix, `systemctl daemon-reload`, restart, repeat.
