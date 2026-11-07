## Hint 1
Who has the file open? `lsof /var/log/app/events.log` or `fuser -v /var/log/app/events.log`.
(`inotifywait -m /var/log/app/events.log` shows the writes happening.)
## Hint 2
Got a PID? `ls -l /proc/<pid>/exe`, `cat /proc/<pid>/cmdline | tr '\0' ' '`,
and most important: what started it? `systemctl status <pid>`.
## Hint 3
Killing it is not enough (it restarts). Stop **and disable** the unit - don't trust its name.
