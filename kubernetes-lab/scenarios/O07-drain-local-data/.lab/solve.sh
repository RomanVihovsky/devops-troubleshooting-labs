kx drain k8s-w2 --ignore-daemonsets --delete-emptydir-data --force --timeout=180s >/dev/null 2>&1 || true
kx uncordon k8s-w2 >/dev/null
wait_rollout maint deploy/cache 180 || true
