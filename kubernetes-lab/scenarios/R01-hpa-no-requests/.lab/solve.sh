kx -n hpa set resources deploy/api --requests=cpu=100m,memory=64Mi >/dev/null
wait_rollout hpa deploy/api 120
m() { kx -n hpa get hpa api -o json | jq -e '[.status.currentMetrics[]? | select(.resource.current.averageUtilization != null)] | length > 0' >/dev/null; }
retry 90 m || true
