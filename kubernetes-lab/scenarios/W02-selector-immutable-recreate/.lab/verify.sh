sel() { kx -n search get deploy search -o jsonpath='{.spec.selector.matchLabels.app}/{.spec.selector.matchLabels.tier}'; }
v2() { [ "$(pods_get search app=search,tier=web / | grep -c '^Search v2 from')" -ge 2 ]; }
check "Deployment search selects app=search,tier=web" test "$(sel)" = search/web
check_eventually 120 "search: 2 Ready pods" deploy_ready search search 2
check_eventually 60 "both greet 'Search v2'" v2
check_eventually 60 "Service search has endpoints" has_endpoints search search
check "Service search answers 200" http_ok search http://search.search.svc/
verdict
