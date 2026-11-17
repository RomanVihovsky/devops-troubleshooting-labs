# a fresh batch run (the original spec, class batch-high) next to 3 Ready storefront pods
value_kept() { [ "$(kx get priorityclass batch-high -o jsonpath='{.value}' 2>/dev/null)" = 1000000 ]; }
check "PriorityClass batch-high keeps its value 1000000" value_kept
check_eventually 150 "storefront: 3 Ready pods before the batch run" deploy_ready storefront storefront 3
uids() { kx -n storefront get pods -l app=storefront -o jsonpath='{.items[*].metadata.uid}' | tr ' ' '\n' | sort | tr '\n' ' '; }
before=$(uids)
kx -n storefront delete job nightly-batch --ignore-not-found --wait=true >/dev/null 2>&1
kx -n storefront delete events --field-selector reason=Preempted >/dev/null 2>&1
ka -f "$STATE_DIR/scenario.s10-batch.yaml" 2>/dev/null
uses_class() { [ "$(kx -n storefront get job nightly-batch -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)" = batch-high ]; }
check "the fresh batch Job runs with class batch-high" uses_class
[ -n "${LAB_EXPECT_FAIL:-}" ] && w=30 || w=60
sleep "$w"
not_preempted() { [ -z "$(kx -n storefront get events --field-selector reason=Preempted -o name 2>/dev/null)" ]; }
same_pods() { [ "$(uids)" = "$before" ] && deploy_ready storefront storefront 3; }
check "no storefront pod was preempted in ${w} s" not_preempted
check "the same 3 storefront pods are still Ready" same_pods
verdict
