data_usage_low() {
  local n cid pct
  n=$(svc_nodes app_web | head -1); cid=$(task_container "$n" app_web)
  pct=$(dkn "$n" exec "$cid" df /data | awk 'NR==2{gsub("%","",$5); print $5}')
  [ -n "$pct" ] && [ "$pct" -lt 50 ]
}
health_twice() { all_nodes_http /health ok 2 && sleep 30 && all_nodes_http /health ok 2; }
check_eventually 30 "/health returns 200 via every node" all_nodes_http /health ok 2
check "/data usage below 50%" data_usage_low
check "/health still 200 after 30 s" health_twice
check "/data usage still below 50%" data_usage_low
verdict
