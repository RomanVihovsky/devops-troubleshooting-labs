not_growing() {
  local a b
  a=$(sx 'stat -c %s /var/log/app/events.log') || return 1
  sleep 15
  b=$(sx 'stat -c %s /var/log/app/events.log') || return 1
  [ "$a" = "$b" ]
}
check "/var/log/app/events.log still exists" sx 'test -s /var/log/app/events.log'
check "nothing has the file open" sx '! fuser /var/log/app/events.log'
check "the writer is not enabled at boot" sx '! systemctl is-enabled --quiet systemd-telemetry'
check "the file did not grow for 15 s" not_growing
verdict
