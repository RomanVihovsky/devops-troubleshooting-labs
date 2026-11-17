kx apply --server-side --field-manager=pipeline-inventory --force-conflicts -f inventory-api.yaml >/dev/null
wait_rollout inventory deploy/inventory-api
