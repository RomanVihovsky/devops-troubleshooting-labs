new=$(recall y08_new)
val() { kx -n partners get secret api-key -o jsonpath='{.data.apikey}' 2>/dev/null | base64 -d; }
one_writer() {
  [ "$(kx -n partners get externalsecrets -o json | jq -r '[.items[] | select((.spec.target.name // .metadata.name) == "api-key") | .metadata.name] | join(",")')" = api-key ]
}
owner() {
  [ "$(kx -n partners get externalsecret api-key -o jsonpath='{.spec.target.creationPolicy}' 2>/dev/null)" = Owner ] \
    && [ "$(kx -n partners get secret api-key -o jsonpath='{.metadata.ownerReferences[?(@.kind=="ExternalSecret")].name}' 2>/dev/null)" = api-key ]
}
legacy_gone() { ! gx "/repos/lab/gitops/contents/envs/partners/api-key-legacy.yaml?ref=main" >/dev/null 2>&1; }
check_eventually 120 "only ExternalSecret api-key writes Secret api-key" one_writer
check_eventually 90 "ExternalSecret api-key owns the Secret (creationPolicy Owner)" owner
check "the legacy ExternalSecret is gone from Git" legacy_gone
samples=""; stable=1
for _ in $(seq 10); do
  v=$(val); [ "$v" = "$new" ] && samples="${samples}n" || { samples="${samples}x"; stable=0; }
  sleep 9
done
steady() { [ "$stable" = 1 ]; }
check "Secret api-key holds the new key for 90 s ($samples)" steady
check_eventually 120 "app partners is Synced and Healthy" argo_app_ok partners
verdict
