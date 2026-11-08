# count nginx starts on a node since $T0 (systemd journal)
starts() { nx "$1" "journalctl -u nginx --since @$T0 -o cat --no-pager | grep -c '^Started nginx'"; }
once() { [ "$(starts "$1")" = 1 ]; }
alert() { eda_post "{\"check\": \"nginx\", \"host\": \"$1\", \"status\": \"down\", \"summary\": \"lab verify\"}"; }

check "the activation starts from the CI checkout (rulebooks/web.yml)" eda_restart /ci
nx web1 "systemctl stop nginx"; nx web3 "systemctl stop nginx"
T0=$(date +%s); sleep 1
for n in web1 web1 web3 web1 web1 web1 web3 web1 web1 web1; do alert "$n"; done
check_eventually 60 "web1 is healed" svc_active web1 nginx
check_eventually 30 "web3 is healed too (a different host inside the window)" svc_active web3 nginx
[ -n "${LAB_EXPECT_FAIL:-}" ] || sleep 20     # a queued storm would keep restarting now
echo "nginx starts since the burst: web1=$(starts web1) web3=$(starts web3)" >> "$VERIFY_LOG"
check "exactly one nginx start on web1 for 8 alerts" once web1
check "exactly one nginx start on web3 for 2 alerts" once web3
check "site.yml converges (check mode: no changes)" converged site.yml
eda_restart /work >/dev/null 2>&1 || true
verdict
