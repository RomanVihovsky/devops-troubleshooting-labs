# S05: minDomains 3 with 2 zones: the global minimum counts as 0, so each zone takes only maxSkew (1) pod
kns search
ka -f search-api.yaml
phases() { kx -n search get pods -l app=search-api -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' | sort | uniq -c | tr -s ' ' | tr '\n' ' '; }
two_pending() { [ "$(phases)" = " 2 Pending  2 Running " ]; }
retry 90 two_pending || die "expected 2 Running + 2 Pending, got: $(phases)"
