# C07: the token Secret was created --from-file from a file ending in "\n"; labapp sends it as-is
kns ledger
tok="pgw_$(openssl rand -hex 16)"
remember c07_token "$tok"
printf '%s\n' "$tok" > token.txt                     # an editor's trailing newline
kx -n ledger create secret generic gw-token --from-literal=token="$tok" --dry-run=client -o yaml | ka -f -
kx -n ledger create secret generic partner-token --from-file=token=token.txt --dry-run=client -o yaml | ka -f -
ka -f ledger.yaml
wait_rollout ledger deploy/partner-gw
newline_err() { local o; o=$(kx -n ledger logs deploy/ledger --tail=50 2>/dev/null) || true; grep -q 'Invalid return character' <<<"$o"; }
retry 90 newline_err || die "ledger never hit the newline error"
! deploy_ready ledger ledger 2 || die "ledger is Ready"
