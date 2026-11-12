# R01: an HPA on CPU utilization for a container without a CPU request
kns hpa
ka -f api.yaml
wait_rollout hpa deploy/api
no_metric() { kx -n hpa get hpa api -o json | jq -e '[.status.conditions[]? | select(.type == "ScalingActive" and .status == "False")] | length > 0' >/dev/null; }
retry 120 no_metric || die "the HPA has a metric"
