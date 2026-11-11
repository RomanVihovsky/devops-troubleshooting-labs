data_kept() { [ "$(bx kv get -mount=secret -field=api_token shop 2>/dev/null)" = "$(recall y06_token)" ]; }
t0=$(date -u +%FT%TZ)
if [ -z "${LAB_EXPECT_FAIL:-}" ] && bao_unsealed; then
  kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
fi
refreshed() { es_ready shop shop-secrets && [ "$(kx -n shop get externalsecret shop-secrets -o jsonpath='{.status.refreshTime}')" \> "$t0" ]; }
check_eventually 30 "OpenBao unsealed" bao_unsealed
check "the shop secrets are the ones from before (no re-init)" data_kept
check_eventually 120 "ClusterSecretStore openbao Ready" store_ready
check_eventually 120 "shop-secrets refreshed after a forced sync" refreshed
check_eventually 60 "shop.lab end to end" shop_ok
verdict
