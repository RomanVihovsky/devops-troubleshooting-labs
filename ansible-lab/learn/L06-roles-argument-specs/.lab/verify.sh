envf() { nx "$1" "cat $2" 2>/dev/null | grep -v '^#'; }
want=$'ACME_PORT=8443\nACME_MODE=prod\nACME_FEATURES=search,cart'
rejects() { ! ap_json site.yml --check "$@" && out_has "argument"; }
no_port() {
  sed 's/      appconfig_port: 8443//' "$CI/site.yml" > "$CI/.lab-noport.yml"
  ! ap_json .lab-noport.yml --check && out_has "appconfig_port"
}
check "web1 (Debian): /etc/default/acme" test "$(envf web1 /etc/default/acme)" = "$want"
check "web2 (Rocky): /etc/sysconfig/acme" test "$(envf web2 /etc/sysconfig/acme)" = "$want"
check "appconfig_mode: chaos fails argument validation" rejects -e appconfig_mode=chaos
check "a call without appconfig_port fails validation" no_port
check "site.yml converges" converged site.yml
verdict
