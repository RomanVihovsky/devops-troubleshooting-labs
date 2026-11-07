# The backup cron job never ran
**LNX-118** · P1 · Reporter: DBA

The new DB backup job lives in `/etc/cron.d/` (for testing it's scheduled **every
minute**). No file has ever appeared in `/var/backups/db/`. Running the exact command
from the cron file by hand as root works perfectly. No error mails, nothing.

**Test**: cron itself produces `/var/backups/db/db-<today's date>.dump` (non-empty)
within ~70 s (`./lab verify` deletes old dumps and waits for a new one).
