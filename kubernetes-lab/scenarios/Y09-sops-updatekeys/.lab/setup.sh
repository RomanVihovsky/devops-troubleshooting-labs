# Y09: secrets/prod.enc.yaml encrypted for the team key; later alice's recipient is added to .sops.yaml, but
# nobody runs sops updatekeys
k="$STATE_DIR/y09-alice.key"
rm -f "$k"; age-keygen -o "$k" 2>/dev/null; chmod 600 "$k"
sed -n 's/^# public key: //p' "$k" > alice.age.pub
pw="pg-$(openssl rand -hex 8)"
remember y09_password "$pw"
export SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" PW=$pw ALICE=$(cat alice.age.pub)
gitops_commit "prod: database secret (sops)" "dev-bob" <<'SNIP'
mkdir -p secrets
printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: prod-db\n  namespace: prod\ntype: Opaque\nstringData:\n  username: app\n  password: %s\n' "$PW" > secrets/prod.enc.yaml
sops -e -i secrets/prod.enc.yaml
! grep -q "$PW" secrets/prod.enc.yaml
SNIP
gitops_commit "onboarding: alice can decrypt the secrets" "dev-bob" <<'SNIP'
python3 - "$ALICE" <<'PY'
import sys, yaml
d = yaml.safe_load(open(".sops.yaml"))
for r in d["creation_rules"]:
    r["age"] = r["age"] + "," + sys.argv[1]
yaml.safe_dump(d, open(".sops.yaml", "w"), sort_keys=False)
PY
SNIP
