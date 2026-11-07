usage_low() { [ "$(sx "df --output=pcent /data | tail -1 | tr -dc 0-9")" -lt 50 ]; }
can_write() { sx 'dd if=/dev/zero of=/data/.verify bs=1M count=10 status=none && rm -f /data/.verify'; }
same_pid()  { [ "$(mainpid queue-worker)" = "$(recall pid)" ] && active queue-worker; }
check "queue-worker still runs with the same PID" same_pid
check "/data is below 50% used" usage_low
check "a 10 MB file can be written to /data" can_write
verdict
