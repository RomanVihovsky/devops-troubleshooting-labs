t0=$(recall w08_t0)
new_success() { kx -n cron get jobs -o json | jq -e --arg t "$t0" '[.items[] | select((.metadata.ownerReferences // [])[0].name == "export"
  and .metadata.creationTimestamp > $t and .status.succeeded >= 1)] | length > 0' >/dev/null; }
cj() { kx -n cron get cronjob export -o jsonpath='{.spec.suspend}|{.spec.schedule}|{.spec.concurrencyPolicy}'; }
no_hang() { ! kx -n cron get pods -o json | jq -e '[.items[] | select(.status.phase == "Running" and ((now - (.status.startTime | fromdateiso8601)) > 120))] | length > 0' >/dev/null; }
check "not suspended, schedule */1 * * * *, Forbid" test "$(cj)" = "false|*/1 * * * *|Forbid"
check_eventually 150 "a Job created by export after the incident started completed" new_success
check_eventually 60 "no export run is hanging (none running > 2 min)" no_hang
verdict
