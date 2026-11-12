kx -n blog rollout resume deploy/blog >/dev/null
wait_rollout blog deploy/blog 120
