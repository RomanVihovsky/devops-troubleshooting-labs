kns ledger
v=$(openssl rand -hex 10); remember p06_pw "$v"
kx -n ledger create secret generic ledger-db --from-literal=passwd="$v" --dry-run=client -o yaml | ka -f -
ka -f ledger.yaml
cce() { kx -n ledger get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -q CreateContainerConfigError; }
retry 120 cce || die "no CreateContainerConfigError"
