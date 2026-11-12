val() { kx -n t12 get secret "$1" -o jsonpath="{.data.$2}" 2>/dev/null | base64 -d 2>/dev/null; }
ann() { kx -n t12 get sealedsecret "$1" -o jsonpath="{.metadata.annotations.sealedsecrets\.bitnami\.com/$2}" 2>/dev/null; }
strict_ok() { [ "$(val api-key key)" = K3y-t12 ] && [ -z "$(ann api-key namespace-wide)$(ann api-key cluster-wide)" ]; }
nswide_ok() { [ "$(val shared-config mode)" = blue ] && [ "$(ann shared-config namespace-wide)" = true ]; }
cwide_ok() { [ "$(val banner text)" = hello ] && [ "$(ann banner cluster-wide)" = true ]; }
backup_ok() {
  [ -s sealing-key.backup.yaml ] || return 1
  python3 -c 'import sys, yaml, base64
want = open(sys.argv[2]).read().strip()
for d in yaml.safe_load_all(open(sys.argv[1])):
    for o in (d or {}).get("items", [d or {}]):
        c = (o.get("data") or {}).get("tls.crt")
        if c and base64.b64decode(c).decode().strip() == want and (o.get("data") or {}).get("tls.key"): sys.exit(0)
sys.exit(1)' sealing-key.backup.yaml "$SEALED_CERT"
}
keys_gt() { [ "$(kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key --no-headers 2>/dev/null | wc -l)" -gt "$(recall t12_keys)" ]; }
legacy_ok() { [ "$(val legacy password)" = 0ld-but-g0ld ]; }
check_eventually 60 "api-key decrypted, scope strict" strict_ok
check_eventually 60 "shared-config decrypted, scope namespace-wide" nswide_ok
check_eventually 60 "banner decrypted, scope cluster-wide" cwide_ok
check "sealing-key.backup.yaml holds the original key (matches the controller's original cert)" backup_ok
check "the controller has more keys than before (the drill created a new one)" keys_gt
check_eventually 90 "t12/legacy decrypted (old key restored)" legacy_ok
verdict
