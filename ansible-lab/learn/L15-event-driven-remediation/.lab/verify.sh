started_at() { nx "$1" "systemctl show nginx -p ActiveEnterTimestampMonotonic --value"; }
alert() { eda_post "{\"check\": \"$1\", \"host\": \"$2\", \"status\": \"$3\", \"summary\": \"lab verify\"}"; }
shop_ok() { http_get "http://$1:8080/" | grep -q "shop on $1"; }
web3_untouched() { [ "$(started_at web3)" = "$WEB3_T" ]; }

check "the activation starts from the CI checkout (rulebooks/nginx.yml)" eda_restart /ci
WEB3_T=$(started_at web3)
nx web1 "systemctl stop nginx"
alert nginx web1 down
check_eventually 60 "a 'nginx down' alert for web1 brings nginx back" svc_active web1 nginx
check_eventually 15 "web1 serves the shop page again" shop_ok web1
sleep 3
check "web3's nginx was not restarted" web3_untouched

nx web3 "systemctl stop nginx"
alert nginx web3 up
alert disk web3 down
[ -n "${LAB_EXPECT_FAIL:-}" ] || sleep 15
check "an 'up' alert and a 'disk' alert run nothing (nginx on web3 stays stopped)" not svc_active web3 nginx
nx web3 "systemctl start nginx"
nx web1 "systemctl start nginx"
check "site.yml converges (check mode: no changes)" converged site.yml
eda_restart /work >/dev/null 2>&1 || true
verdict
