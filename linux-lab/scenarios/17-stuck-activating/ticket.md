# Service hangs in "activating", then gets killed
**LNX-117** · P2 · Reporter: platform team

`cachewarm` was migrated from an old init script to systemd. Now `systemctl start
cachewarm` hangs for ~15 s, the unit sits in `activating (start)`, then systemd kills it
and tries again. The app's own log says it started fine and was serving on :8084 the
whole time.

**Test**: `cachewarm` stays active (no restarts) for 25 s and `curl localhost:8084/` answers.
