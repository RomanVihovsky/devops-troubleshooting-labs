installs() { ctl_ci "ansible-galaxy install -r requirements.yml" >> "$VERIFY_LOG" 2>&1; }
coll_ver() { ctl_ci "ansible-galaxy collection list $1 --format json" 2>/dev/null | jq -r --arg c "$1" '[.[] | .[$c].version // empty] | first'; }
role_ver() { ctl_ci "cat roles/acme.logrotate/meta/.galaxy_install_info" 2>/dev/null | sed -n 's/^version: *//p' | tr -d "'\""; }
check "a fresh checkout installs everything from requirements.yml" installs
check "community.general 14.0.0" test "$(coll_ver community.general)" = 14.0.0
check "ansible.posix 2.2.2" test "$(coll_ver ansible.posix)" = 2.2.2
check "role acme.logrotate at v1.0.0" test "$(role_ver)" = v1.0.0
check "site.yml converges with the installed content" eval 'applies site.yml && converged site.yml'
check "logrotate keeps 14 days (v1.0.0 behaviour) on both nodes" eval 'nx web1 "grep -q \"rotate 14\" /etc/logrotate.d/acme" && nx web2 "grep -q \"rotate 14\" /etc/logrotate.d/acme"'
verdict
