three_managers() { [ "$(dk node ls --format '{{.Status}} {{.ManagerStatus}}' | grep -cE '^Ready (Leader|Reachable)$')" -eq 3 ]; }
no_down() { dk node ls >/dev/null && ! dk node ls --format '{{.Status}}' | grep -qv Ready; }
same_service() { [ "$(dk service inspect -f '{{.ID}}' app_web)" = "$(cat "$STATE_DIR/scenario.svcid")" ]; }
check "swarm answers management commands" dk node ls
check_eventually 30 "3 managers: 1 Leader + 2 Reachable" three_managers
check_eventually 60 "no Down/Unknown nodes left" no_down
check "app_web is the original service" same_service
check_eventually 90 "web answers via every node" all_nodes_http / 'Hello'
verdict
