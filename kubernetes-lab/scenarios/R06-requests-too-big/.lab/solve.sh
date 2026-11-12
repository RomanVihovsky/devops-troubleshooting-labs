kx -n analytics2 set resources deploy/analytics --requests=memory=256Mi --limits=memory=512Mi >/dev/null
wait_rollout analytics2 deploy/analytics 120
