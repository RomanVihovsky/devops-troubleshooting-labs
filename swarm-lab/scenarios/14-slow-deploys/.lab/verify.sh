graceful_stop() {
  local n cid t0
  n=$(svc_nodes app_web | head -1); cid=$(task_container "$n" app_web)
  [ -n "$cid" ] || return 1
  t0=$SECONDS
  dkn "$n" stop -t 30 "$cid" >/dev/null
  [ $((SECONDS - t0)) -le 5 ] && dkn "$n" logs "$cid" 2>&1 | grep -q 'SIGTERM received'
}
check_eventually 30 "app_web is 3/3" svc_converged app_web
check "a web container stops in < 5 s with a graceful shutdown" graceful_stop
check_eventually 40 "web answers via every node" all_nodes_http / 'Hello'
verdict
