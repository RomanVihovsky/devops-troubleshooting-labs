sed -i 's/nodeSelector: {disktype: ssd}/nodeSelector: {disk: ssd}/' indexer.yaml
kx apply -f indexer.yaml >/dev/null
wait_rollout indexer deploy/indexer
