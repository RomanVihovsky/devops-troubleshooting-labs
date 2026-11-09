W="$LAB_DIR/workspace/gitops"; team=$(cat team.age.pub); pw=$(cat password.txt)
git -C "$W" pull -q
mkdir -p "$W/secrets"
python3 - "$W/.sops.yaml" "$team" <<'PY'
import sys, yaml
f, team = sys.argv[1], sys.argv[2]
d = yaml.safe_load(open(f))
for r in d["creation_rules"]:
    if "secrets" in r.get("path_regex", "") and team not in r["age"]:
        r["age"] = r["age"] + "," + team
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: t14-db\ntype: Opaque\nstringData:\n  password: %s\n' "$pw" > "$W/secrets/t14.yaml"
(cd "$W" && SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" sops -e -i secrets/t14.yaml && SOPS_AGE_KEY_FILE="$STATE_DIR/age.key" sops updatekeys -y secrets/t14.yaml >/dev/null 2>&1)
grep -q "$pw" "$W/secrets/t14.yaml" && die "plaintext left in secrets/t14.yaml"
git -C "$W" add .sops.yaml secrets/t14.yaml
git -C "$W" commit -qm "t14: encrypted db secret for the payments team"
git -C "$W" push -q origin main 2>/dev/null
