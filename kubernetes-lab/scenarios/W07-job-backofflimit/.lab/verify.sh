complete() { [ "$(kx -n batch get job nightly-report -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)" = True ]; }
log_ok() { kx -n batch logs job/nightly-report 2>/dev/null | grep -q 'report done'; }
script_kept() { kx -n batch get cm report-script -o jsonpath='{.data.report\.sh}' | grep -q 'echo "report done"' \
                && kx -n batch get job nightly-report -o json | jq -e '[.spec.template.spec.volumes[]? | select(.configMap.name == "report-script")] | length > 0' >/dev/null; }
check_eventually 120 "Job nightly-report Complete" complete
check "its log says report done" log_ok
check "the script comes from ConfigMap report-script (unchanged)" script_kept
verdict
