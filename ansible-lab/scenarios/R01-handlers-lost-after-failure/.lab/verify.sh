next_release() {
  local v="2.5.$RANDOM"
  applies site.yml -e "shop_version=$v" && [ "$(http_get http://web1:8080/version)" = "$v" ]
}
check "web1 serves 2.4.1" eval '[ "$(http_get http://web1:8080/version)" = 2.4.1 ]'
check "site.yml runs green" applies site.yml
check "site.yml converges" converged site.yml
check "a new release goes live in one run (smoke check passes)" next_release
check "back on 2.4.1" applies site.yml
verdict
