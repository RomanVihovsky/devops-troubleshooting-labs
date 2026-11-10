demo_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H 'Host: demo.lab' -H "Authorization: Bearer $(cat "$STATE_DIR/demo-token")" http://192.168.56.200/; }
up() { [ "$(demo_code)" = 200 ]; }
raw() { gx "/repos/lab/gitops/raw/$1?ref=main"; }
no_rc() { ! raw envs/demo/values.yaml | grep -q '2.0.0-rc1'; }
history_kept() { gx "/repos/lab/gitops/commits?sha=main&limit=30" | jq -e '[.[] | select(.commit.message | test("2.0.0-rc1"))] | length > 0' >/dev/null; }
autosync() { raw apps/demo.yaml | python3 -c 'import sys, yaml
s = yaml.safe_load(sys.stdin)["spec"].get("syncPolicy") or {}
sys.exit(0 if (s.get("automated") or {}).get("selfHeal") is True else 1)'; }
check_eventually 180 "demo.lab answers 200" up
check_eventually 120 "demo Synced + Healthy" argo_app_ok demo
check "main no longer deploys 2.0.0-rc1" no_rc
check "the RC commit is still in main's history (no force-push)" history_kept
check "automated sync + self-heal still on for demo (in Git)" autosync
verdict
