fresh_limit() {   # no persistent fact cache: what a fresh CI runner sees
  docker exec -u ops -w /ci -e ANSIBLE_STDOUT_CALLBACK=ansible.posix.json -e ANSIBLE_CACHE_PLUGIN=memory \
    -e ANSIBLE_NOCOLOR=1 "$CTL" ansible-playbook site.yml --limit web "$@" > "$CI/.lab-ap.raw" 2>>"$VERIFY_LOG"
  local rc=$?; sed -n '/^{$/,/^}$/p' "$CI/.lab-ap.raw" > "$CI/.lab-ap.json"; return $rc
}
applied() { fresh_limit && stats_ok '.failures == 0 and .unreachable == 0'; }
converged_limit() { fresh_limit --check && stats_ok '.changed == 0 and .failures == 0 and .unreachable == 0'; }
db_untouched() { ! jq -e '.stats.db1.changed > 0' "$CI/.lab-ap.json" >/dev/null 2>&1; }
check "site.yml --limit web runs on a fresh runner" applied
check "web1's db.conf points at db1 (10.78.0.21)" eval 'nx web1 "grep -qx \"host = 10.78.0.21\" /etc/acme/db.conf"'
check "--limit web converges (check mode)" converged_limit
check "nothing is changed on db1" db_untouched
verdict
