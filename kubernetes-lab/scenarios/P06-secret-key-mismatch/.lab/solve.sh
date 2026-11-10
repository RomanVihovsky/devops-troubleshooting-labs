sed -i 's/key: password}/key: passwd}/' ledger.yaml
kx apply -f ledger.yaml >/dev/null
wait_rollout ledger deploy/ledger
