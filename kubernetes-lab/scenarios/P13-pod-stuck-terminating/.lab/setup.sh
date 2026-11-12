# P13: the worker ignores SIGTERM with a 600 s grace period, and its pod carries an orphaned finalizer
kns queue
ka -f queue-worker.yaml
wait_rollout queue deploy/queue-worker
old=$(kx -n queue get pods -l app=queue-worker -o name | head -1)
kx -n queue patch "$old" --type merge -p '{"metadata":{"finalizers":["example.com/cleanup"]}}' >/dev/null
kx -n queue delete "$old" --wait=false >/dev/null
terminating() { [ -n "$(kx -n queue get "$old" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ]; }
retry 30 terminating || die "the pod is not Terminating"
wait_rollout queue deploy/queue-worker 120 || true
