survives_redeploy() {
  force_update app_web || return 1
  sleep 4
  all_nodes_http / 'Hello' 3
}
check_eventually 20 "proxy answers via every node" all_nodes_http / 'Hello' 3
check "still answers after a forced redeploy of web" survives_redeploy
verdict
