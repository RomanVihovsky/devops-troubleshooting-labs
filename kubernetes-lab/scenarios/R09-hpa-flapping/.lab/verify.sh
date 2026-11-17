hpa_kept() {
  kx -n catalog get hpa catalog-api -o json | jq -e '.spec.scaleTargetRef.name == "catalog-api" and .spec.minReplicas == 2
    and .spec.maxReplicas == 6 and ([.spec.metrics[] | select(.resource.name == "cpu" and .resource.target.averageUtilization == 50)] | length == 1)' >/dev/null
}
check "the HPA still scales catalog-api 2-6 at 50 % CPU" hpa_kept
check_eventually 60 "traffic-replay is running" deploy_ready catalog traffic-replay 1
# sample the replica count every 5 s for 150 s (more than two bursts and gaps)
samples=""; drops=0; prev=""
for _ in $(seq 30); do
  r=$(kx -n catalog get deploy catalog-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
  samples="$samples $r"
  if [ -n "$prev" ] && [ -n "$r" ] && [ "$r" -lt "$prev" ]; then drops=$((drops + 1)); fi
  [ -n "$r" ] && prev=$r
  sleep 5
done
no_drop() { [ "$drops" = 0 ]; }
check "no scale-down in 150 s of bursty load (replicas:$samples)" no_drop
verdict
