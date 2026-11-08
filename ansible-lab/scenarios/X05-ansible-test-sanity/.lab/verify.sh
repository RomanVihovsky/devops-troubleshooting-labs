sanity_ok() { ctl_ci "ci/sanity.sh" >> "$VERIFY_LOG" 2>&1; }
no_ignores() {
  local f
  for f in "$CI"/tests/sanity/ignore-*.txt; do
    [ -e "$f" ] || continue
    grep -qvE '^\s*(#|$)' "$f" && return 1
  done
  ! grep -rqsE '#\s*(noqa|pylint:\s*disable)' "$CI/plugins"
}
smoke_ok() { ci_json ci/smoke.sh && stats_ok '.failures == 0 and .unreachable == 0'; }
adhoc() { ctl_ci "ANSIBLE_COLLECTIONS_PATH=/tmp/ci-smoke ansible web1 -b -m acme.ops.app_flag -a '$1'" >> "$VERIFY_LOG" 2>&1; }
default_path() {
  local v="v$RANDOM"
  adhoc "name=verify_default value=$v" && nx web1 "grep -qx 'verify_default=$v' /etc/shop/flags.conf"
}
check "ci/sanity.sh passes (ansible-test sanity, all tests)" sanity_ok
check "no sanity ignore entries, no noqa / pylint: disable comments" no_ignores
check "ci/smoke.sh passes (set, idempotent, check mode, absent)" smoke_ok
check "without path: the flag lands in /etc/shop/flags.conf (the documented default)" default_path
check "state=enabled is rejected (not in the documented choices)" not adhoc "name=x value=y state=enabled"
verdict
