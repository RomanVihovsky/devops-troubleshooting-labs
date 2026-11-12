PW=$(recall t14_password)
TMP=$(mktemp -d)
git clone -q "http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git" "$TMP/repo" 2>/dev/null
F=$TMP/repo/secrets/t14.yaml
team=$(cat team.age.pub 2>/dev/null)
encrypted() { [ -f "$F" ] && grep -q '^sops:' "$F" && grep -q 'ENC\[' "$F" && ! grep -q "$PW" "$F"; }
two_recipients() { [ "$(python3 -c 'import sys, yaml; print(len(yaml.safe_load(open(sys.argv[1]))["sops"]["age"]))' "$F" 2>/dev/null)" = 2 ]; }
dec_with() { SOPS_AGE_KEY_FILE=$1 sops -d "$F" 2>/dev/null | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); sys.exit(0 if d["metadata"]["name"] == "t14-db" and str(d["stringData"]["password"]) == sys.argv[1] else 1)' "$PW"; }
rule_has_team() { [ -n "$team" ] && grep -q "$team" "$TMP/repo/.sops.yaml"; }
no_plaintext() { ! git -C "$TMP/repo" log -p --all 2>/dev/null | grep -q "$PW"; }
check "secrets/t14.yaml on main is SOPS-encrypted (no plaintext password in it)" encrypted
check "encrypted for 2 age recipients" two_recipients
check "decrypts with the lab key to t14-db with the right password" dec_with "$STATE_DIR/age.key"
check "decrypts with the team key" dec_with "$STATE_DIR/t14-team.key"
check ".sops.yaml on main lists the team key" rule_has_team
check "the password appears nowhere in the Git history" no_plaintext
rm -rf "$TMP"
verdict
