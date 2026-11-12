kx -n team-b set resources deploy/worker --requests=cpu=200m,memory=64Mi --limits=cpu=500m,memory=256Mi >/dev/null
wait_rollout team-b deploy/worker 120
