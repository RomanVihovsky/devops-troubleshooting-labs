sxi <<'S'
rm -f /etc/cron.d/nightly.backup
cat > /etc/cron.d/nightly-backup <<'A'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * root backup-db --out /var/backups/db/db-$(date +\%F).dump >> /var/log/backup-db.log 2>&1
A
S
