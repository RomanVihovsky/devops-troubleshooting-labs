drift_repaired() {
  nx app1 "rm -f /etc/acme/enabled.conf; userdel acme" || return 1
  applies site.yml && stats_ok '.changed >= 2' && nx app1 "test -L /etc/acme/enabled.conf && id acme >/dev/null"
}
check "a second run changes nothing" idempotent site.yml
check "drift (symlink, user) is repaired and reported as changed" drift_repaired
check "release unpacked, config enabled" eval 'nx app1 "test -f /opt/acme/current/VERSION && test \"\$(readlink /etc/acme/enabled.conf)\" = /etc/acme/app.conf"'
check "ansible-lint: no-changed-when, command-instead-of-*" lint_ok "--offline --nocolor -t no-changed-when,command-instead-of-module,command-instead-of-shell site.yml"
check "site.yml converges" converged site.yml
verdict
