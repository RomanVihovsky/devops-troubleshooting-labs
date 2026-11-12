sed -i 's|^      serviceAccountName: janitor|      serviceAccountName: janitor\n      automountServiceAccountToken: true|' janitor.yaml
kx apply -f janitor.yaml >/dev/null
wait_rollout janitor deploy/janitor
