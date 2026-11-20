api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
cert_long() { nx "$CP" 'openssl x509 -checkend 25920000 -noout -in /etc/kubernetes/pki/apiserver.crt' </dev/null >/dev/null 2>&1; }
uids() {
  [ "$(kx get ns prod -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall b06_ns)" ] \
    && [ "$(kx -n prod get deploy ledger -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall b06_deploy)" ] \
    && [ "$(kx -n prod get pvc ledger-data -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall b06_pvc)" ]
}
live_pod() { kx -n prod get pods -l app=ledger -o json | jq -r '[.items[] | select(.metadata.deletionTimestamp == null)
  | select(any(.status.conditions[]?; .type == "Ready" and .status == "True"))][0].metadata.name // empty'; }
balance() { local p; p=$(live_pod); [ -n "$p" ] && [ "$(kx -n prod exec "$p" -- labapp get http://localhost:8080/kv/balance 2>/dev/null)" = "$(recall b06_balance)" ]; }
member_inode() {
  nx "$CP" "python3 -c 'import yaml; d = yaml.safe_load(open(\"/etc/kubernetes/manifests/etcd.yaml\"))
print([v[\"hostPath\"][\"path\"] for v in d[\"spec\"][\"volumes\"] if v[\"name\"] == \"etcd-data\"][0])' | xargs -I{} stat -c %i {}/member" </dev/null
}
restored() { local i; i=$(member_inode); [ -n "$i" ] && [ "$i" != "$(recall b06_inode)" ]; }
check "the API server certificate is valid for > 300 days" cert_long
check_eventually 180 "the API answers" api_ok
check "prod, ledger and ledger-data are back with their original UIDs" uids
check_eventually 180 "ledger is Ready" deploy_ready prod ledger 1
check_eventually 60 "ledger serves the same balance as before" balance
check "etcd runs from restored data" restored
check_eventually 180 "all nodes Ready" nodes_ready
verdict
