ws_sed 's/nr_inodes=4096/nr_inodes=65536/; s#- sessions:/sessions#- sessions_v2:/sessions#; s/^  sessions:$/  sessions_v2:/'
deploy_stack
sleep 3
retry 90 all_nodes_http /health ok 1
