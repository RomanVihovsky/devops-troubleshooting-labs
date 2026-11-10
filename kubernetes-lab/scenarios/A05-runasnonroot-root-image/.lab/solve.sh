sed -i 's|labapp:1.4-root|labapp:1.4|' payments-ui.yaml
kx apply -f payments-ui.yaml >/dev/null
wait_rollout payments-ui deploy/payments-ui
