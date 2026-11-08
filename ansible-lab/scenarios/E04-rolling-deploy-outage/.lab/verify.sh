release_on() { nx "$1" "cat /usr/share/nginx/html/version.txt" 2>/dev/null; }
bad_build_contained() {
  local rc=0 total bad touched=0 n
  docker exec -u ops "$CTL" bash -c 'rm -f /tmp/lab-stop; : > /tmp/lab-curl.log'
  docker exec -d -u ops "$CTL" bash -c 'while [ ! -f /tmp/lab-stop ]; do
      curl -s -o /dev/null -w "%{http_code}\n" --max-time 2 http://lb1/version.txt >> /tmp/lab-curl.log; sleep 0.1; done'
  sleep 1
  ap_json deploy.yml -e app_release=2.0.0-rc1 || rc=$?
  sleep 3
  docker exec -u ops "$CTL" touch /tmp/lab-stop; sleep 0.5
  total=$(docker exec "$CTL" sh -c 'wc -l < /tmp/lab-curl.log')
  bad=$(docker exec "$CTL" sh -c 'grep -vc "^200$" /tmp/lab-curl.log' || true)
  for n in web1 web2 web3; do [ "$(release_on $n)" = 2.0.0-rc1 ] && touched=$((touched + 1)); done
  echo "bad build: rc=$rc requests=$total failed=$bad nodes-on-rc1=$touched" >> "$VERIFY_LOG"
  [ "$rc" -ne 0 ] && [ "$total" -gt 20 ] && [ "${bad:-1}" -eq 0 ] && [ "$touched" -le 1 ]
}
all_in_rotation() {
  nx lb1 "echo 'show stat' | socat stdio /run/haproxy/admin.sock" | awk -F, '$1=="web" && $2 ~ /^web[123]$/ {print $2, $18}' > "$CI/.lab-stat"
  cat "$CI/.lab-stat" >> "$VERIFY_LOG"
  [ "$(grep -c ' UP$' "$CI/.lab-stat")" = 3 ]
}
healthy_deploy() {
  applies deploy.yml -e app_release=1.4.2 &&
    for n in web1 web2 web3; do [ "$(release_on $n)" = 1.4.2 ] || return 1; done
}
check "the current state converges (site.yml, no changes)" converged site.yml
check "a broken release: zero failed requests, at most one node touched, the play stops" bad_build_contained
check "a healthy deploy updates every node again" healthy_deploy
check_eventually 15 "all three web nodes are back in rotation on lb1" all_in_rotation
verdict
