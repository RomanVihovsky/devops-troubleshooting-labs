kx -n checkout apply -f app-config.yaml >/dev/null
kx -n default delete configmap app-config --ignore-not-found >/dev/null
wait_rollout checkout deploy/checkout 180
