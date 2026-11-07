db_on_ssd() { local n; n=$(svc_nodes app_db); [ -n "$n" ] && dk node inspect -f '{{json .Spec.Labels}}' "$n" | grep -q '"ssd"'; }
check_eventually 40 "app_db is 1/1" svc_converged app_db
check "app_db runs on the node labelled ssd" db_on_ssd
check_eventually 30 "shop answers with a hit counter via every node" all_nodes_http / 'hits='
verdict
