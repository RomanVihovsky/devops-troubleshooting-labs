sed -i '/name: BIND_ADDRESS, value: 127.0.0.1/d' ledger-ui.yaml
kx apply -f ledger-ui.yaml >/dev/null
wait_rollout ledger-ui deploy/ledger-ui
