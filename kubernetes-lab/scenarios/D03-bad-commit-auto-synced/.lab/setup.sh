# D03: the release candidate (exits 1 at start: REQUIRED_ENV FEATURE_FLAGS_URL) with a Recreate strategy
gitops_commit "demo: release candidate 2.0.0-rc1 (Recreate: schema change) (INC-2240)" <<'SNIP'
cat >> envs/demo/values.yaml <<'YML'
image:
  tag: "2.0.0-rc1"
strategy:
  type: Recreate
YML
SNIP
argo_refresh demo
down() { [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H 'Host: demo.lab' http://192.168.56.200/)" = 503 ]; }
retry 300 down || die "demo did not go down"
