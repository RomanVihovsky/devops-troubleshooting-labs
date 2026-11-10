sed -i 's|labapp:1.4.0|labapp:1.4|' catalog.yaml
kx apply -f catalog.yaml >/dev/null
wait_rollout catalog deploy/catalog
