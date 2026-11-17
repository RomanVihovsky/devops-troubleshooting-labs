all_synced() { kx get sealedsecrets -A -o json | jq -e '[.items[] | any(.status.conditions[]?; .type == "Synced" and .status == "True")] | all and length > 0' >/dev/null; }
es_all() { kx get externalsecrets -A -o json | jq -e '[.items[] | any(.status.conditions[]?; .type == "Ready" and .status == "True")] | all and length > 0' >/dev/null; }
old_key() { kx -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[*].data.tls\.crt}' 2>/dev/null | tr ' ' '\n' | grep -qx "$(recall b07_cert)"; }
on_main() { [ "$(kx -n argocd get application lab-apps -o jsonpath='{.spec.source.targetRevision}' 2>/dev/null)" = main ]; }
git_same() { [ "$(gx /repos/lab/gitops/branches/main 2>/dev/null | jq -r .commit.id)" = "$(recall b07_main)" ]; }
apps_ok() { argo_app_ok lab-apps && argo_app_ok demo && argo_app_ok shop; }
check_eventually 60 "OpenBao is unsealed" bao_unsealed
check "the root app follows main" on_main
check_eventually 240 "lab-apps, demo and shop are Synced and Healthy" apps_ok
check "the original sealing key is back" old_key
check_eventually 120 "every SealedSecret is Synced" all_synced
check_eventually 120 "every ExternalSecret is Ready" es_all
check_eventually 120 "demo.lab: 401 without token, 200 with it" demo_auth_ok
check_eventually 120 "shop.lab end to end" shop_ok
check "Git main unchanged" git_same
verdict
