new_dump() {
  local f; f="/var/backups/db/db-$(sx 'date +%F').dump"
  sx 'rm -f /var/backups/db/*.dump'
  retry 75 sx "test -s $f"
}
check "cron creates today's dump within 75 s (takes up to 75 s...)" new_dump
verdict
