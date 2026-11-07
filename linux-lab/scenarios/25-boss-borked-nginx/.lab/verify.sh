burst_ok() {
  sx "seq 50 | xargs -P50 -I{} curl -s -o /dev/null -w '%{http_code}\n' --max-time 2 localhost/ | sort | uniq -c" \
    | awk '{n += $1; if ($2 == "200") ok += $1} END {exit !(n == 50 && ok == 50)}'
}
check_eventually 10 "nginx is active" active nginx
check "curl localhost/ shows the shop" sx 'curl -fs localhost/ | grep -q "Shop is open"'
check "curl localhost/assets/app.css -> 200" sx 'curl -fs -o /dev/null localhost/assets/app.css'
check "50 concurrent requests all succeed" burst_ok
verdict
