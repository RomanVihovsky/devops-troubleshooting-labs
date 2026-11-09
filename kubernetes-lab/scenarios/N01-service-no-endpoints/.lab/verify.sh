has_endpoints() {
  [ -n "$(kx -n orders get endpointslices -l kubernetes.io/service-name=backend -o jsonpath='{.items[*].endpoints[*].addresses[0]}')" ]
}
pods_keep_labels() { [ "$(kx -n orders get pods -l app=back-end --no-headers 2>/dev/null | wc -l)" -ge 2 ]; }
check_eventually 60 "Service backend has endpoints" has_endpoints
check_eventually 60 "in-cluster http://backend.orders/items -> 200" http_ok orders http://backend.orders/items
check_eventually 60 "the frontend reaches the backend (/upstream -> 200)" http_ok orders http://frontend.orders/upstream
check "the backend pods still carry app=back-end" pods_keep_labels
verdict
