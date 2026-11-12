leaked=$(recall y10_leaked)
W=$(mktemp -d)
git clone -q "http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git" "$W" 2>/dev/null
f="$W/secrets/new-service.enc.yaml"
all_enc() { python3 - "$f" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
vals = list((d.get("data") or {}).values()) + list((d.get("stringData") or {}).values())
sys.exit(0 if vals and all(str(v).startswith("ENC[") for v in vals) else 1)
PY
}
rule_ok() { python3 - "$W/.sops.yaml" <<'PY'
import re, sys, yaml
rules = yaml.safe_load(open(sys.argv[1]))["creation_rules"]
r = [x for x in rules if re.search(x.get("path_regex", ".*"), "secrets/new-service.enc.yaml")][0]
rx = r.get("encrypted_regex")
sys.exit(0 if rx and re.search(rx, "data") and re.search(rx, "stringData") else 1)
PY
}
newpw() { SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" "$BIN_DIR/sops" -d "$f" 2>/dev/null | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin) or {}
print((d.get("stringData") or {}).get("password") or "")'; }
new=$(newpw)
auth() { [ "$(kx -n newsvc exec deploy/redis -- redis-cli -a "$1" --no-auth-warning ping 2>/dev/null)" = PONG ]; }
leaked_rejected() { ! auth "$leaked"; }
not_in_file() { ! grep -qF "$leaked" "$f"; }
check "the file holds no plaintext value (all ENC[...])" all_enc
check ".sops.yaml covers data and stringData for this file" rule_ok
check "it decrypts with the team key to a NEW password" test -n "$new" -a "$new" != "$leaked"
check "the leaked password is not anywhere in the file" not_in_file
check_eventually 120 "Redis accepts the new password" auth "$new"
check "Redis rejects the leaked password" leaked_rejected
rm -rf "$W"
verdict
