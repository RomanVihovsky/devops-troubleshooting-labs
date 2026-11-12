sed -i 's/port: 8081}/port: http}/' profile.yaml
kx apply -f profile.yaml >/dev/null
wait_rollout profile deploy/profile
