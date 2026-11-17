all_synced() { kx get sealedsecrets -A -o json | jq -e '[.items[] | any(.status.conditions[]?; .type == "Synced" and .status == "True")] | all and length > 0' >/dev/null; }
secret_back() { kx -n demo get secret demo-auth >/dev/null 2>&1; }
git_same() { [ "$(gx /repos/lab/gitops/branches/main 2>/dev/null | jq -r .commit.id)" = "$(recall y02_main)" ]; }
old_key() { kx -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[*].data.tls\.crt}' 2>/dev/null | tr ' ' '\n' | grep -qx "$(recall y02_cert)"; }
check "the controller has the original sealing key" old_key
check_eventually 120 "every SealedSecret is Synced" all_synced
check "Secret demo/demo-auth exists" secret_back
check_eventually 120 "demo.lab: 401 without token, 200 with it" demo_auth_ok
check "Git unchanged (nothing re-sealed)" git_same
verdict
