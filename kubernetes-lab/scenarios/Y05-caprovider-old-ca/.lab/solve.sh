eso_store_restore
kx annotate clustersecretstore openbao force-sync="$(date +%s)" --overwrite >/dev/null
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
retry 120 store_ready || true
