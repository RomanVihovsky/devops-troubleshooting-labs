sxi <<'S'
mkdir -p /var/backups/db
cat > /usr/local/sbin/backup-db <<'A'
#!/bin/bash
# backup-db --out FILE : dump the database
[ "$1" = --out ] && [ -n "$2" ] || { echo "usage: backup-db --out FILE" >&2; exit 2; }
echo "-- dump of appdb taken $(date -Is)" > "$2"
A
chmod 755 /usr/local/sbin/backup-db
cat > /etc/cron.d/nightly.backup <<'A'
# Nightly DB backup  (TEST SCHEDULE: every minute - change to "15 2 * * *" later)
* * * * * root backup-db --out /var/backups/db/db-$(date +%F).dump
A
S
