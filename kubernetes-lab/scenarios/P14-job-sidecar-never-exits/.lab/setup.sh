# P14: the log shipper is a regular container that never exits, so the Job's pod never succeeds
kns reports
ka -f nightly-report.yaml
report_done() { [ "$(kx -n reports get pods -l job-name=nightly-report -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="report")].state.terminated.exitCode}' 2>/dev/null)" = 0 ]; }
retry 120 report_done || die "the report container never finished"
sleep 5
[ "$(kx -n reports get job nightly-report -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')" != True ] || die "the Job completed"
