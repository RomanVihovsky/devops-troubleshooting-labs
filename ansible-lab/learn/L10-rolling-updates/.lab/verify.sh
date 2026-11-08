v="2.1.$RANDOM"   # unique per verify run: earlier probes may have deployed other versions
rel_on() { nx "$1" "cat /usr/share/nginx/html/version.txt" 2>/dev/null; }
zero_loss_deploy() {
  local rc=0 total bad
  docker exec -u ops "$CTL" bash -c 'rm -f /tmp/lab-stop; : > /tmp/lab-curl.log'
  docker exec -d -u ops "$CTL" bash -c 'while [ ! -f /tmp/lab-stop ]; do
      curl -s -o /dev/null -w "%{http_code}\n" --max-time 2 http://lb1/version.txt >> /tmp/lab-curl.log; sleep 0.1; done'
  sleep 1
  ap_json deploy.yml -e app_release=$v || rc=$?
  sleep 2; docker exec -u ops "$CTL" touch /tmp/lab-stop; sleep 0.5
  total=$(docker exec "$CTL" sh -c 'wc -l < /tmp/lab-curl.log')
  bad=$(docker exec "$CTL" sh -c 'grep -vc "^200$" /tmp/lab-curl.log' || true)
  echo "deploy $v: rc=$rc requests=$total failed=$bad" >> "$VERIFY_LOG"
  [ "$rc" -eq 0 ] && [ "$total" -gt 15 ] && [ "${bad:-1}" -eq 0 ] && [ "$(rel_on app1)" = "$v" ] && [ "$(rel_on app2)" = "$v" ]
}
migrated_once() { [ "$(nx db1 "grep -c 'migrate to $v' /var/lib/acme/migrations.log")" = 1 ]; }
in_rotation() {
  [ "$(nx lb1 "echo 'show stat' | socat stdio /run/haproxy/admin.sock" | awk -F, '$1=="app" && $2 ~ /^app[12]$/ && $18=="UP"' | wc -l)" = 2 ]
}
check "deploying a new version loses zero requests and updates both nodes" zero_loss_deploy
check_eventually 15 "both app nodes are back in rotation" in_rotation
check "its migration is logged exactly once" migrated_once
check "a repeated deploy of that version changes nothing" converged deploy.yml -e app_release=$v
check "...and still logs the migration only once" migrated_once
verdict
