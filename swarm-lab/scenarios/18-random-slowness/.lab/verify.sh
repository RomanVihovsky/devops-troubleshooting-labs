all_fast() {
  local n i t
  for n in "${BASE_NODES[@]}"; do
    for i in $(seq 10); do
      t=$(curl -fsS -o /dev/null -w '%{time_total}' --max-time 3 "http://$(node_ip "$n"):$APP_PORT/") || return 1
      awk -v t="$t" 'BEGIN{exit !(t < 0.3)}' || return 1
    done
  done
}
check_eventually 20 "10 requests via every node answer in < 300 ms" all_fast
verdict
