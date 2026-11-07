check_eventually 90 "app_agent runs on all 3 nodes" svc_on_all_nodes app_agent 3
check_eventually 30 "node-agent answers via every node" all_nodes_http / 'node-agent'
verdict
