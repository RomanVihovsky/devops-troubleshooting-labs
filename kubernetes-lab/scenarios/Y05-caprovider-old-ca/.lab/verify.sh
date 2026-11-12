fp() { openssl x509 -noout -fingerprint -sha256 2>/dev/null; }
ca_current() { [ "$(kx -n external-secrets get configmap lab-ca -o jsonpath='{.data.ca\.crt}' | fp)" = "$(fp < "$CA_DIR/ca.crt")" ]; }
store_shape() { kx get clustersecretstore openbao -o json | jq -e '.spec.provider.vault
  | (.server | startswith("https://")) and .caProvider.type == "ConfigMap" and .caProvider.name == "lab-ca"
    and .caProvider.namespace == "external-secrets" and .caProvider.key == "ca.crt"' >/dev/null; }
t0=$(date -u +%FT%TZ)
[ -n "${LAB_EXPECT_FAIL:-}" ] || kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
refreshed() { es_ready shop shop-secrets && [ "$(kx -n shop get externalsecret shop-secrets -o jsonpath='{.status.refreshTime}')" \> "$t0" ]; }
check "lab-ca holds the current lab CA (same fingerprint as \$BAO_CACERT)" ca_current
check "the store still verifies TLS: https, caProvider = ConfigMap external-secrets/lab-ca" store_shape
check_eventually 120 "ClusterSecretStore openbao Ready" store_ready
check_eventually 120 "shop-secrets refreshed after a forced sync" refreshed
check_eventually 60 "shop.lab end to end" shop_ok
verdict
