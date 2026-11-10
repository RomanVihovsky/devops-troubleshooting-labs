api_same() { [ "$(kx -n inventory-api get deploy,svc -o json | jq -c '[.items[] | {k: .kind, n: .metadata.name, s: .spec.selector}]')" = "$(recall n05_api)" ]; }
check_eventually 60 "storefront /upstream -> 200 (reaches the API)" http_ok storefront http://storefront.storefront/upstream
check "inventory-api unchanged" api_same
verdict
