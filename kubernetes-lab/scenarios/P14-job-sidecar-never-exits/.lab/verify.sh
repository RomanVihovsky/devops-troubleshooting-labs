job() { kx -n reports get job nightly-report -o json 2>/dev/null; }
complete() { [ "$(kx -n reports get job nightly-report -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)" = True ]; }
# the report container still writes run.log (nobody "fixed" it by printing to stdout)
writes_file() { job | jq -e '[.spec.template.spec.containers[] | select(.name == "report") | .args[0] | contains(">> /var/log/report/run.log")] | any' >/dev/null; }
# a shipper runs alongside it: a native sidecar (restartPolicy Always init container) running ship-logs
shipper() { job | jq -e '[.spec.template.spec.initContainers[]? | select(.restartPolicy == "Always" and ((.args // []) | index("ship-logs")))] | length > 0' >/dev/null; }
shipped() { local o; o=$(kx -n reports logs job/nightly-report --all-containers 2>/dev/null); grep -q 'report complete' <<<"$o"; }
check_eventually 120 "Job nightly-report is Complete" complete
check "the report container still writes /var/log/report/run.log" writes_file
check "a log shipper (native sidecar running ship-logs) runs in the Job's pod" shipper
check_eventually 30 "the shipped log contains 'report complete'" shipped
verdict
