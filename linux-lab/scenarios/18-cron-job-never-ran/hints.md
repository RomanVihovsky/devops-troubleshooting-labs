## Hint 1
Is cron even reading the file? Watch `sudo journalctl -u cron -f` (or `/var/log/syslog`)
for a minute. `man cron` - the **Debian-specific** notes say which file names in
`/etc/cron.d` are ignored.
## Hint 2
Once cron runs it, where does the output go? (No MTA -> discarded.) Redirect the job's
output to a file to see the error: `... >> /tmp/backup.log 2>&1`. Cron runs with a minimal
environment - `PATH`?
## Hint 3
In a crontab, an unescaped `%` means "newline / stdin" - the command gets cut there.
Write it as `\%`. Three fixes in total: file name, PATH, `%`.
