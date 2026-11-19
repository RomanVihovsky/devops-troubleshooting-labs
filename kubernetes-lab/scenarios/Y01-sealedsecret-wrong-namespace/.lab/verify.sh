NEW=$(recall y01_new); OLD=$(cat "$STATE_DIR/demo-token")
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H 'Host: demo.lab' -H "Authorization: Bearer $1" http://192.168.56.200/; }
# six requests in a row: the Service spreads them over the pods, so an old pod still serving shows up
all_say() { local t=$1 want=$2; for _ in 1 2 3 4 5 6; do [ "$(code "$t")" = "$want" ] || return 1; done; }
new_ok() { all_say "$NEW" 200; }
old_rejected() { all_say "$OLD" 401; }
ss_synced() { [ "$(kx -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)" = True ]; }
sealed_in_git() { gx "/repos/lab/gitops/raw/envs/demo/values.yaml?ref=main" | grep -q 'source: sealedSecret' && ! gx "/repos/lab/gitops/raw/envs/demo/values.yaml?ref=main" | grep -q "$NEW"; }
check_eventually 120 "SealedSecret demo/demo-auth decrypted (Synced)" ss_synced
check_eventually 120 "demo Synced + Healthy" argo_app_ok demo
check_eventually 120 "the new token is accepted on demo" new_ok
check_eventually 120 "the old token is rejected (401) - by every pod, once the rollout is through" old_rejected
check "the token is sealed in Git (no plaintext)" sealed_in_git
verdict
