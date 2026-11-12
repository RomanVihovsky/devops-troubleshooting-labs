# W07: the command runs /script/report.sh, the ConfigMap is mounted at /scripts
kns batch
ka -f report.yaml
failed() { [ "$(kx -n batch get job nightly-report -o jsonpath='{.status.conditions[?(@.type=="Failed")].reason}')" = BackoffLimitExceeded ]; }
retry 180 failed || die "the Job did not fail"
