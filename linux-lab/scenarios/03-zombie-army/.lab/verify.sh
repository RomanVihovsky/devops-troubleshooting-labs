no_zombies_15s() {
  local i
  for i in $(seq 8); do
    [ "$(sx 'ps -eo state= | grep -c Z')" -eq 0 ] || return 1
    sleep 2
  done
}
check "report-worker is running" active report-worker
check "no zombies for 15 s" no_zombies_15s
verdict
