vendor_kept() {
  [ "$(kx -n vendor get deploy search -o jsonpath='{.spec.template.spec}' 2>/dev/null | sha256sum)" = "$(recall n13_vendor)" ] \
    && [ "$(kx -n vendor get secret search-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null | sha256sum)" = "$(recall n13_cert)" ]
}
verified_https() {
  kx -n frontend get deploy frontend -o json | jq -e '[.spec.template.spec.containers[0].env[]] as $e
    | ([$e[] | select(.name == "UPSTREAM_URL" and (.value | startswith("https://")))] | length == 1)
    and ([$e[] | select(.name == "UPSTREAM_CA_FILE" and (.value // "") != "")] | length == 1)' >/dev/null
}
upstream_200() { local o; o=$(pods_get frontend app=frontend /upstream); [ "$(grep -c '"status": *200' <<<"$o")" -ge 2 ]; }
check_eventually 150 "frontend: 2 Ready pods (upstream check passes)" deploy_ready frontend frontend 2
check_eventually 30 "both frontend pods get 200 from the vendor" upstream_200
check "frontend calls the vendor over https with UPSTREAM_CA_FILE (verification on)" verified_https
check "the vendor's deployment and certificate are unchanged" vendor_kept
verdict
