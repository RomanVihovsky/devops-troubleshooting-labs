# What keeps writing to this log?
**LNX-106** · P3 · Reporter: storage team

`/var/log/app/events.log` grows all day - it filled the disk last week. Nobody knows
which program writes it. Find it and stop it **permanently** (it must not come back
after a reboot). Do **not** delete the log: it's evidence for the security team.

**Test**: the file still exists, has not grown for 15 s, no process has it open, and
whatever wrote it will not start again at boot.
