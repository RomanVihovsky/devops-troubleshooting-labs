no_dstate_15s() {
  local i
  for i in $(seq 8); do
    [ "$(sx "ps -eo state= | grep -c D")" -eq 0 ] || return 1
    sleep 2
  done
}
four_workers() { [ "$(sx "pgrep -fc 'thumbnailer/worker.py'")" -eq 4 ]; }
check "thumbnailer is running" active thumbnailer
check "all 4 workers are alive" four_workers
check "no D-state processes for 15 s" no_dstate_15s
verdict
