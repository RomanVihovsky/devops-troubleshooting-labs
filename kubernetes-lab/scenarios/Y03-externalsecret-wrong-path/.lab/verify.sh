keys3() { [ "$(kx -n shop get secret shop-secrets -o json 2>/dev/null | jq '.data | keys | length')" = 3 ]; }
git_key() { gx "/repos/lab/gitops/raw/envs/shop/values.yaml?ref=main" | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin) or {}; k = ((d.get("secret") or {}).get("externalSecret") or {}).get("remoteKey", "shop")
sys.exit(0 if k == "shop" else 1)'; }
only_shop() { ! bx kv get -mount=secret shop/app >/dev/null 2>&1 && bx kv get -mount=secret shop >/dev/null 2>&1; }
check_eventually 120 "ExternalSecret shop/shop-secrets Ready" es_ready shop shop-secrets
check "Secret shop-secrets has its 3 keys" keys3
check_eventually 180 "shop.lab end to end" shop_ok
check "the fix is in Git: remoteKey is shop" git_key
check "OpenBao: the secret lives only at secret/shop (nothing copied to shop/app)" only_shop
verdict
