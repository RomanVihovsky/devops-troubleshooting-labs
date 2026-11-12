gitops_commit "shop: remoteKey back to shop (INC-2266)" student <<'SNIP'
sed -i 's|^\(\s*remoteKey:\) shop/app$|\1 shop|' envs/shop/values.yaml
! grep -q 'shop/app' envs/shop/values.yaml
SNIP
argo_refresh shop
retry 120 argo_app_ok shop || true
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
retry 120 es_ready shop shop-secrets || true
retry 180 shop_ok || true
