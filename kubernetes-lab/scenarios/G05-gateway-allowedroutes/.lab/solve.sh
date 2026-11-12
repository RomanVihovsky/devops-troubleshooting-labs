kx label namespace gw-shop gateway-access=team --overwrite >/dev/null
kx -n gw-infra patch gateway team --type json -p '[{"op":"replace","path":"/spec/listeners/0/allowedRoutes","value":{"namespaces":{"from":"Selector","selector":{"matchLabels":{"gateway-access":"team"}}}}}]' >/dev/null
ok() { [ "$(http_out http://192.168.56.200/ shop.team.lab)" = 200 ]; }
retry 60 ok || true
