inodes_low() { [ "$(sx "df --output=ipcent /var/lib/app/sessions | tail -1 | tr -dc 0-9")" -lt 50 ]; }
live_kept()  { [ "$(sx 'ls /var/lib/app/sessions | grep -c ^live_')" -eq 15 ]; }
check "all 15 recent sessions still exist" live_kept
check "inode usage below 50%" inodes_low
check_eventually 10 "/login returns 200" sx 'curl -fs localhost:8082/login'
verdict
