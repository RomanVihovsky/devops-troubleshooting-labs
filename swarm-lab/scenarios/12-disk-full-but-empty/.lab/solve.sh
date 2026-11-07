ws_sed 's/LOG_LEVEL: debug.*/LOG_LEVEL: info/'
deploy_stack
sleep 3
retry 90 all_nodes_http /health ok 1
