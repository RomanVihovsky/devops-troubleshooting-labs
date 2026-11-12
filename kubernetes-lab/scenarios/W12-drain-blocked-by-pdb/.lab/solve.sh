kx -n ha patch pdb ha-api --type merge -p '{"spec":{"minAvailable":2}}' >/dev/null
kx drain k8s-w1 --ignore-daemonsets --delete-emptydir-data --timeout=180s >/dev/null 2>&1 || true
kx uncordon k8s-w1 >/dev/null
wait_rollout ha deploy/ha-api 180 || true
