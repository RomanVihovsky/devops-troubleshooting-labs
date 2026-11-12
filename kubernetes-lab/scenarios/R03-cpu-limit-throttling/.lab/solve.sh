kx -n quotes set resources deploy/quotes --limits=cpu=1 --requests=cpu=100m >/dev/null
wait_rollout quotes deploy/quotes 180
