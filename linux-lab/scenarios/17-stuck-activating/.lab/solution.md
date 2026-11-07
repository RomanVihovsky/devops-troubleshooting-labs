# Solution - Type=forking for a program that doesn't fork

**Root cause**: the unit says `Type=forking` + `PIDFile=` (copied from the old init script
world, where daemons double-fork). This program stays in the foreground, so systemd waits
for a fork/PID file that never comes; after `TimeoutStartSec=15` it kills the service and
`Restart=on-failure` repeats the cycle. Meanwhile the app happily serves - until killed.

**Diagnose**
```
systemctl status cachewarm      # Active: activating (start) ... / "start operation timed out. Terminating."
systemctl cat cachewarm         # Type=forking, PIDFile=/run/cachewarm.pid (never written)
```

**Fix**: `Type=simple` (or `exec`), remove `PIDFile=`, `daemon-reload`, restart.

**Interview notes**: `simple`/`exec` = foreground process is the service; `forking` =
classic daemon (parent exits, PIDFile names the child); `notify` = app calls
`sd_notify(READY=1)`; `oneshot` = runs to completion. Wrong `Type=` explains many
"hangs in activating", "service starts then immediately stops", and "systemd lost track
of the PID" problems.
