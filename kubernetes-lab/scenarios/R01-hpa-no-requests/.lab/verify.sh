hpa() { kx -n hpa get hpa api -o json; }
has_metric() { hpa | jq -e '[.status.currentMetrics[]? | select(.resource.name == "cpu" and .resource.current.averageUtilization != null)] | length > 0' >/dev/null; }
same_target() { hpa | jq -e '.spec.minReplicas == 1 and .spec.maxReplicas == 5 and ([.spec.metrics[] | select(.resource.name == "cpu" and .resource.target.averageUtilization == 60)] | length == 1)' >/dev/null; }
scaled() { [ "$(hpa | jq '.status.desiredReplicas // 0')" -gt 1 ]; }
check "the HPA still targets 60% CPU, 1-5 replicas" same_target
check_eventually 90 "the HPA reports a CPU utilization" has_metric
if [ -z "${LAB_EXPECT_FAIL:-}" ] && has_metric; then
  # load for ~2 minutes from a detached pod (load_test would block the checks)
  kx -n hpa run lab-load-r01 --restart=Never --image="$LABAPP_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
    labapp load http://api.hpa.svc:8080/items -c 8 -d 150 -q >/dev/null 2>&1
  check_eventually 180 "under load the HPA scales api beyond 1 replica" scaled
  kx -n hpa delete pod lab-load-r01 --wait=false >/dev/null 2>&1
else
  check "under load the HPA scales api beyond 1 replica" false
fi
verdict
