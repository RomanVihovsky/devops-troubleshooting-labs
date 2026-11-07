# Solution - three classic cron traps

1. **File name**: Debian's cron ignores files in `/etc/cron.d` whose names don't match
   run-parts rules (letters, digits, `_` and `-` only) - `nightly.backup` has a dot.
2. **PATH**: cron jobs run with `PATH=/usr/bin:/bin`; `backup-db` is in `/usr/local/sbin`.
   Works in your shell, "command not found" in cron.
3. **`%`**: in a crontab, `%` ends the command (the rest becomes stdin). `$(date +%F)`
   must be written `$(date +\%F)`.

And the reason you saw nothing: cron mails job output, and there is no MTA - so every
error was silently discarded ("No MTA installed, discarding output" in the cron log).

**Diagnose**
```
sudo journalctl -u cron -f            # is the job started at all? any CMD lines?
man cron                              # "Debian-specific" file naming rules
# temporarily append  >> /tmp/backup.log 2>&1  to see errors
```

**Fix** (`/etc/cron.d/nightly-backup`):
```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * root backup-db --out /var/backups/db/db-$(date +\%F).dump >> /var/log/backup-db.log 2>&1
```

**Interview notes**: also - the user field exists only in `/etc/crontab` and `/etc/cron.d`
(not in `crontab -e`), files must end with a newline, scripts in `/etc/cron.daily` must be
executable and dot-free too, and systemd timers (`systemctl list-timers`) log to the journal
by default - one reason teams move to them.
