kns payments-ui
ka -f payments-ui.yaml
cce() { kx -n payments-ui get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -q CreateContainerConfigError; }
retry 120 cce || die "no CreateContainerConfigError"
