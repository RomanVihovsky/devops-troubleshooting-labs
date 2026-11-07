info "Adding manager2 and manager3"
compose --profile ha up -d manager2 manager3 >/dev/null 2>&1
wait_dockerd manager2 90; wait_dockerd manager3 90
join_node manager2 manager
join_node manager3 manager
retry 90 nodes_ready 5
deploy_stack
retry 90 svc_converged app_web
dk service inspect -f '{{.ID}}' app_web > "$STATE_DIR/scenario.svcid"
info "Disaster: manager2 + manager3 lose their disks"
compose --profile ha rm -sfv manager2 manager3 >/dev/null 2>&1
compose --profile ha up -d manager2 manager3 >/dev/null 2>&1
wait_dockerd manager2 90; wait_dockerd manager3 90
retry 60 sh -c '! docker exec lab-manager1 docker node ls'
