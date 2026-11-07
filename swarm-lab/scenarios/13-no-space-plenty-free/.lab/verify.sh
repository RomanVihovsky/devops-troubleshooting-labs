snapshot_kept() { dk service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' app_web | grep -q 'SESSION_SNAPSHOT=5000"'; }
survives_restart() {
  force_update app_web || return 1
  sleep 2
  retry 20 all_nodes_http /health ok 2
}
check_eventually 30 "/health returns 200 via every node" all_nodes_http /health ok 2
check "SESSION_SNAPSHOT is still 5000" snapshot_kept
check "/health still 200 after a forced redeploy" survives_restart
verdict
