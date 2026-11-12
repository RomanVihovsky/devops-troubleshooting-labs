pdb_ok() { kx -n legacyweb get pdb web -o json 2>/dev/null | jq -e '.apiVersion == "policy/v1" and .spec.minAvailable == 1 and .spec.selector.matchLabels.app == "web"' >/dev/null; }
ok200() { [ "$(http_out http://192.168.56.200/ legacy.lab)" = 200 ]; }
check "PDB web (policy/v1, minAvailable 1, app=web)" pdb_ok
check "Ingress web exists" kx -n legacyweb get ingress web
check_eventually 60 "legacy.lab answers 200 through the LB" ok200
verdict
