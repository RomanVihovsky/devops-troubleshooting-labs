## Hint 1
`systemctl status cachewarm` and `journalctl -u cachewarm`: what is systemd waiting for
when it says "start operation timed out"?
## Hint 2
`systemctl cat cachewarm` - look at `Type=` and `PIDFile=`. With `Type=forking`, systemd
considers the service started only when the launched process **forks and the parent exits**.
Does this program do that? (`ps -o pid,ppid,cmd` while it's activating)
## Hint 3
The app runs in the foreground. Use `Type=simple` (or `exec`), drop `PIDFile=`, daemon-reload, restart.
