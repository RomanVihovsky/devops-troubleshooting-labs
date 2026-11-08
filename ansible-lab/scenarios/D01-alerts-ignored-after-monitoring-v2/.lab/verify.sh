started_at() { nx "$1" "systemctl show nginx -p ActiveEnterTimestampMonotonic --value"; }
v2() { eda_post "{\"version\": 2, \"alert\": {\"check\": \"$1\", \"state\": \"$3\", \"target\": {\"fqdn\": \"$2.acme.internal\", \"env\": \"prod\"}, \"summary\": \"lab verify\"}, \"sent_at\": \"$(date -u +%FT%TZ)\"}"; }
shop_ok() { http_get "http://$1:8080/" | grep -q "shop on $1"; }
web1_untouched() { [ "$(started_at web1)" = "$WEB1_T" ]; }

check "the activation starts from the CI checkout (rulebooks/web.yml)" eda_restart /ci
nx web1 "systemctl start nginx"; WEB1_T=$(started_at web1)
nx web3 "systemctl stop nginx"
v2 nginx web3 critical
check_eventually 60 "a v2 'critical' alert for web3.acme.internal brings nginx back on web3" svc_active web3 nginx
check_eventually 15 "web3 serves the shop page again" shop_ok web3
sleep 3
check "web1 was not touched" web1_untouched

nx web1 "systemctl stop nginx"
v2 nginx web1 ok
[ -n "${LAB_EXPECT_FAIL:-}" ] || sleep 15
check "a v2 'ok' alert runs nothing (nginx on web1 stays stopped)" not svc_active web1 nginx
nx web1 "systemctl start nginx"; nx web3 "systemctl start nginx"
check "site.yml converges (check mode: no changes)" converged site.yml
eda_restart /work >/dev/null 2>&1 || true
verdict
