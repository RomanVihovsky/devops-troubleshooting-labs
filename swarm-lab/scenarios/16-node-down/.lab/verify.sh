w1_ready() { dk node ls --format '{{.Hostname}} {{.Status}}' | grep -q '^worker1 Ready$'; }
not_rebooted() { [ "$(docker inspect -f '{{.State.StartedAt}}' lab-worker1)" = "$(cat "$STATE_DIR/scenario.started")" ]; }
check_eventually 45 "worker1 is Ready" w1_ready
check_eventually 45 "app_agent runs on all 3 nodes" svc_on_all_nodes app_agent 3
check "worker1 was not rebooted" not_rebooted
verdict
