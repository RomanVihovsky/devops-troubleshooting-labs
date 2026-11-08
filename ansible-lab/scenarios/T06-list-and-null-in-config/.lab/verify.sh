host_get() { docker exec "$CTL" curl -fsS --max-time 5 -H "Host: $1" http://web1/; }
check "site.yml deploys" applies site.yml
check "shop.acme.test serves the shop" eval 'host_get shop.acme.test | grep -qx "ACME shop"'
check "www.acme.test serves the shop" eval 'host_get www.acme.test | grep -qx "ACME shop"'
check "rendered vhost has no list syntax / empty directive" eval 'nx web1 "! grep -qE \"[][]|error_page 404 *;\" /etc/nginx/conf.d/shop.conf"'
check "site.yml converges" converged site.yml
check "a set shop_error_page still renders error_page" eval 'ap_json site.yml --check --diff -e shop_error_page=/oops.html; out_has "error_page 404 /oops.html"'
verdict
