pw=$(recall y09_password)
W=$(mktemp -d)
git clone -q "http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git" "$W" 2>/dev/null
dec() { SOPS_AGE_KEY_FILE=$1 "$BIN_DIR/sops" -d "$W/secrets/prod.enc.yaml" 2>/dev/null; }
same_content() { dec "$1" | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin) or {}
s = d.get("stringData") or {}
sys.exit(0 if s.get("username") == "app" and s.get("password") == sys.argv[1] and d["metadata"]["name"] == "prod-db" else 1)' "$pw"; }
no_plaintext() { ! grep -qF "$pw" "$W/secrets/prod.enc.yaml"; }
alice_listed() { grep -qF "$(cat alice.age.pub 2>/dev/null || sed -n 's/^# public key: //p' "$STATE_DIR/y09-alice.key")" "$W/.sops.yaml"; }
check "decrypts with alice's key, content unchanged" same_content "$STATE_DIR/y09-alice.key"
check "decrypts with the team key, content unchanged" same_content "$STATE_DIR/age.key"
check "still encrypted (no plaintext password in Git)" no_plaintext
check ".sops.yaml still lists alice" alice_listed
rm -rf "$W"
verdict
