kx -n search delete deploy search >/dev/null
kx apply -f search-v2.yaml >/dev/null
wait_rollout search deploy/search 120
