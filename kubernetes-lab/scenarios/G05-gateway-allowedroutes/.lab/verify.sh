accepted() { [ "$(kx -n "$1" get httproute "$2" -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].status}')" = True ]; }
ok200() { [ "$(http_out http://192.168.56.200/ shop.team.lab)" = 200 ]; }
selector() { kx -n gw-infra get gateway team -o json | jq -e '.spec.listeners[] | select(.name == "web") | .allowedRoutes.namespaces
  | .from == "Selector" and .selector.matchLabels["gateway-access"] == "team"' >/dev/null; }
other_refused() { ! accepted gw-other other && [ "$(http_out http://192.168.56.200/ other.team.lab)" != 200 ]; }
check_eventually 90 "route gw-shop/shop Accepted" accepted gw-shop shop
check_eventually 60 "shop.team.lab answers 200 through the LB" ok200
check "the Gateway admits namespaces labelled gateway-access=team" selector
check "the route from gw-other is still refused" other_refused
verdict
