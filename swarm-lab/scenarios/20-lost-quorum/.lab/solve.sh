dk swarm init --force-new-cluster --advertise-addr 172.30.0.11 >/dev/null
sleep 3
# only the dead managers - workers may briefly show Unknown right after the re-init
for id in $(dk node ls --format '{{.ID}} {{.Hostname}} {{.Status}}' | awk '$2 ~ /^manager[23]$/ && $3!="Ready"{print $1}'); do
  dk node demote "$id" >/dev/null 2>&1 || true
  dk node rm --force "$id" >/dev/null
done
join_node manager2 manager
join_node manager3 manager
retry 60 sh -c "[ \$(docker exec lab-manager1 docker node ls --format '{{.ManagerStatus}}' | grep -cE 'Leader|Reachable') -eq 3 ]"
retry 90 svc_converged app_web
# post-recovery: the survivor's routing mesh keeps stale overlay neighbours -> restart its dockerd
docker restart lab-manager1 >/dev/null
wait_dockerd manager1 90
retry 120 sh -c "[ \$(docker exec lab-manager1 docker node ls --format '{{.Status}}' 2>/dev/null | grep -c Ready) -eq 5 ]"
retry 90 all_nodes_http / 'Hello' 1
