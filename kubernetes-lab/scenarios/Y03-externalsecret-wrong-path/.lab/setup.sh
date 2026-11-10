# Y03: remoteKey points at a path that doesn't exist; the Secret is deleted and the pods restarted
gitops_commit "shop: secret path cleanup (PLAT-77)" <<'SNIP'
sed -i '/^  externalSecret:/a\    remoteKey: shop/app' envs/shop/values.yaml
grep -q 'remoteKey: shop/app' envs/shop/values.yaml
SNIP
argo_refresh shop
es_err() { [ "$(kx -n shop get externalsecret shop-secrets -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = False ]; }
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
retry 180 es_err || die "the ExternalSecret never failed"
kx -n shop delete secret shop-secrets --ignore-not-found >/dev/null
kx -n shop delete pod -l app.kubernetes.io/name=api --wait=false >/dev/null
kx -n shop delete pod -l app.kubernetes.io/name=frontend --wait=false >/dev/null
broken() { kx -n shop get pods -l app.kubernetes.io/name=api -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -q CreateContainerConfigError; }
retry 120 broken || die "the api pods did not break"
