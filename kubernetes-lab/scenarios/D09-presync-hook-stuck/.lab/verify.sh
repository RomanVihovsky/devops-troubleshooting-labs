op() { kx -n argocd get application billing -o json | jq -c '.status.operationState'; }
# the last operation Succeeded and ran the migration Job as a PreSync hook that Succeeded
synced_with_hook() {
  op | jq -e '.phase == "Succeeded" and ([.syncResult.resources[]? | select(.kind == "Job" and .hookType == "PreSync" and .hookPhase == "Succeeded")] | length > 0)' >/dev/null
}
# the settings come from the chart (Argo CD tracks it: instance label), not from a ConfigMap made by hand
from_chart() { [ "$(kx -n billing get configmap billing -o jsonpath='{.metadata.labels.app\.kubernetes\.io/instance}' 2>/dev/null)" = billing ]; }
check_eventually 300 "billing: last sync Succeeded with a PreSync migration hook" synced_with_hook
check_eventually 120 "billing Synced + Healthy" argo_app_ok billing
check "ConfigMap billing comes from the chart (not made by hand)" from_chart
# a fresh sync must not hang either (the next release)
t0=$(date -u +%FT%TZ)
[ -n "${LAB_EXPECT_FAIL:-}" ] || argo_sync billing
resynced() { op | jq -e --arg t "$t0" '.startedAt > $t' >/dev/null && synced_with_hook; }
check_eventually 240 "a fresh sync also Succeeds (PreSync migration included)" resynced
check_eventually 120 "billing pods Ready" deploy_ready billing billing
verdict
