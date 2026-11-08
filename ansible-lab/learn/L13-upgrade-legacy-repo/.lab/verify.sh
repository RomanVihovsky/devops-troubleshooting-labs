clean_run() {   # rc 0 and no deprecation warnings, with fact injection off (the 2.24 default)
  docker exec -u ops -w /ci -e ANSIBLE_NOCOLOR=1 -e ANSIBLE_INJECT_FACT_VARS=False "$CTL" ansible-playbook site.yml > "$CI/.lab-run.log" 2>&1
  local rc=$?; cat "$CI/.lab-run.log" >> "$VERIFY_LOG"
  [ $rc -eq 0 ] && ! grep -q 'DEPRECATION WARNING' "$CI/.lab-run.log"
}
spec() {
  local n=$1 want=$2
  nx $n "stat -c %a /var/spool/acme/q1 /var/spool/acme/q2 /var/spool/acme/q3" | grep -c '^750$' | grep -qx 3 &&
  [ "$(nx $n "stat -c %a /etc/acme/app.conf")" = 640 ] && nx $n "test -f /etc/acme/legacy.conf" &&
  [ "$(nx $n "cat /etc/acme/os.txt")" = "$want" ]
}
switch_works() { ap_json site.yml --check -e '{"create_dirs": false}' && task_skipped "Spool directories"; }
check "runs on 2.22 warning-free, with INJECT_FACTS_AS_VARS=False" clean_run
check "web1 matches the spec (Debian 12)" spec web1 "Debian 12 (2 hosts in play)"
check "web2 matches the spec (Rocky 9)" spec web2 "Rocky 9 (2 hosts in play)"
check "create_dirs: false skips the spool directories" switch_works
check "site.yml converges" converged site.yml
verdict
