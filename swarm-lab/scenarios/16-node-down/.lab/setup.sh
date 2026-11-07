deploy_stack
retry 60 svc_on_all_nodes app_agent 3
docker inspect -f '{{.State.StartedAt}}' lab-worker1 > "$STATE_DIR/scenario.started"
inject worker1 'iptables -t raw -A OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP' \
               'iptables -t raw -D OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP'
retry 90 sh -c "docker exec lab-manager1 docker node ls --format '{{.Hostname}} {{.Status}}' | grep -q 'worker1 Down'"
