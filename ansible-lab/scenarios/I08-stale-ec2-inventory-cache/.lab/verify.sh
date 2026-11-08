fleet() { aws list | awk '$2 == "running" && $1 ~ /^shop-web-/ {print $1}' | sort | xargs; }
job_hits_fleet() {
  local want hit
  want=$(fleet)
  ci_json ci/deploy.sh || true
  hit=$(jq -r '.stats | keys | sort | join(" ")' "$CI/.lab-ap.json" 2>/dev/null)
  echo "running fleet: [$want] - job hit: [$hit]" >> "$VERIFY_LOG"
  stats_ok '.failures == 0 and .unreachable == 0' && [ "$hit" = "$want" ]
}
serves() { http_get "http://$1:8080/" | grep -q "ACME shop 2.3.0 on $2"; }

check "ci/deploy.sh hits exactly the running web instances and succeeds" job_hits_fleet
check "shop-web-3 (scaled out yesterday) serves release 2.3.0" serves web3 shop-web-3
aws stop shop-web-2 >> "$VERIFY_LOG" 2>&1
aws launch shop-web-4 app1 web >> "$VERIFY_LOG" 2>&1
check "after a scale-in (shop-web-2) and a scale-out (shop-web-4) the very next job hits exactly the new fleet" job_hits_fleet
check "shop-web-4 got the release" serves app1 shop-web-4
aws start shop-web-2 >> "$VERIFY_LOG" 2>&1
aws stop shop-web-4 >> "$VERIFY_LOG" 2>&1
verdict
