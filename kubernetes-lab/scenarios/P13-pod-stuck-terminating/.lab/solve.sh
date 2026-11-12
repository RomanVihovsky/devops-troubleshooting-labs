sed -i 's/terminationGracePeriodSeconds: 600/terminationGracePeriodSeconds: 30/; s/{name: SHUTDOWN_MODE, value: ignore}/{name: SHUTDOWN_MODE, value: graceful}/' queue-worker.yaml
kx apply -f queue-worker.yaml >/dev/null
wait_rollout queue deploy/queue-worker 120 || true
# the old pods still carry the old 600 s grace (and one the orphaned finalizer)
for p in $(kx -n queue get pods -o json | jq -r '.items[] | select(.metadata.deletionTimestamp != null or ((.metadata.finalizers // []) | index("example.com/cleanup"))) | .metadata.name'); do
  kx -n queue patch pod "$p" --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]' >/dev/null 2>&1 || true
  kx -n queue delete pod "$p" --grace-period=0 --force >/dev/null 2>&1 || true
done
