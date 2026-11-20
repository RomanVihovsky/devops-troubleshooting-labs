kx -n ledger create secret generic partner-token --from-literal=token="$(cat token.txt)" --dry-run=client -o yaml | ka -f -
retry 150 deploy_ready ledger ledger 2 || true
