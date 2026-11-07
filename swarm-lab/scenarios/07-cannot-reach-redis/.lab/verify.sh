redis_isolated() {
  local fe; fe=$(dk network inspect -f '{{.ID}}' app_frontend) || return 1
  ! dk service inspect -f '{{json .Spec.TaskTemplate.Networks}}' app_redis | grep -q "$fe"
}
check_eventually 40 "web answers with hits= via every node" all_nodes_http / 'hits='
check "redis is not attached to the frontend network" redis_isolated
verdict
