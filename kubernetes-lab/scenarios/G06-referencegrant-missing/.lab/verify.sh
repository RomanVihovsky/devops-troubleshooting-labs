resolved() { [ "$(kx -n web-front get httproute frontdoor -o jsonpath='{.status.parents[*].conditions[?(@.type=="ResolvedRefs")].status}')" = True ]; }
from_back() { curl -s --max-time 5 -H 'Host: frontdoor.lab' http://192.168.56.200/version | grep -q '"name": *"backend-api"'; }
backend_ns() { kx -n web-front get httproute frontdoor -o json | jq -e '[.spec.rules[].backendRefs[] | select(.namespace == "web-back" and .name == "api")] | length > 0' >/dev/null; }
check_eventually 90 "the route's references resolve" resolved
check_eventually 60 "frontdoor.lab answers from web-back/api" from_back
check "the backend still lives in web-back" backend_ns
verdict
