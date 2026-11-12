one_port() { kx -n portx get networkpolicy -o json | jq -e '[.items[] | select(.spec.podSelector.matchLabels.app == "web") | .spec.ingress[]?.ports[]?]
  | length == 1 and (.[0].port == 8080 or .[0].port == "http")' >/dev/null; }
check_reach <<'ROWS'
portx - web.portx.svc:80 open
ROWS
check "the policy allows exactly the web port" one_port
verdict
