# D01: the release commit - a tag that doesn't exist and a values key the chart doesn't know (silently ignored)
gitops_commit "demo: release 1.4.0 for the French launch (INC-2231)" <<'SNIP'
cat >> envs/demo/values.yaml <<'YML'
image:
  tag: "1.4.0"
app:
  greting: Bonjour
YML
SNIP
argo_refresh demo
pull_fail() { kx -n demo get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -qE 'ErrImagePull|ImagePullBackOff'; }
retry 240 pull_fail || die "demo never tried the bad tag"
