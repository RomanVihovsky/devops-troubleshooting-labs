conf() { nx "$1" "cat /etc/nginx/conf.d/00-tuning.conf" 2>/dev/null; }
prod_ok() { local c; c=$(conf web1); grep -qx 'gzip on;' <<<"$c" && grep -qx 'keepalive_timeout 65;' <<<"$c" && grep -qx 'client_max_body_size 50m;' <<<"$c"; }
staging_ok() { conf web2 | grep -qx 'client_max_body_size 10m;'; }
shared_default_reaches_prod() {
  sed -i 's/keepalive_timeout: 65/keepalive_timeout: 75/' "$CI/group_vars/all.yml"
  ap_json site.yml --check --diff --limit web1; local rc=$?
  sed -i 's/keepalive_timeout: 75/keepalive_timeout: 65/' "$CI/group_vars/all.yml"
  [ $rc -eq 0 ] && out_has 'keepalive_timeout 75'
}
check "prod: gzip on, keepalive 65, 50m uploads" prod_ok
check "staging: 10m uploads" staging_ok
check "a changed shared default still reaches prod" shared_default_reaches_prod
check "no global hash_behaviour = merge" not ws_has 'hash_behaviour|HASH_BEHAVIOUR'
check "site.yml converges" converged site.yml
verdict
