upload() {   # upload <host header>: HTTP code for a 5 MB POST
  docker exec "$CTL" sh -c "head -c 5000000 /dev/zero | curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H 'Host: $1' -X POST --data-binary @- http://web1/" 2>/dev/null
}
base_once() { [ "$(task_result "Base config" | wc -l)" = 1 ]; }
check "a second run changes nothing" idempotent site.yml
check "nginx_base runs once per host" base_once
check "shop rejects a 5 MB upload (413)" eval '[ "$(upload shop.acme.test)" = 413 ]'
check "api accepts a 5 MB upload (200)" eval '[ "$(upload api.acme.test)" = 200 ]'
check "site.yml converges" converged site.yml
verdict
