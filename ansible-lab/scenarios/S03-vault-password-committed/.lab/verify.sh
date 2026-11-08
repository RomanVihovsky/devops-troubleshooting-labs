pwfile() { printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "$2" > "$CI/.lab-$1.sh"; chmod +x "$CI/.lab-$1.sh"; }
pwfile old "$(recall old_vault)"; pwfile new "$(recall new_vault)"
printf "[defaults]\n" > "$CI/.lab-empty.cfg"   # ANSIBLE_CONFIG=/dev/null is rejected by 2.22
# every vaulted payload in the checkout -> .lab-vault-N.txt (whole files and inline !vault strings)
python3 - "$CI" <<'PY'
import os, sys, re
root = sys.argv[1]; n = 0
for d, dirs, files in os.walk(root):
    dirs[:] = [x for x in dirs if x not in (".git", ".ansible")]
    for f in files:
        if f.startswith(".lab-"): continue
        p = os.path.join(d, f)
        try: s = open(p).read()
        except Exception: continue
        blocks = [s] if s.startswith("$ANSIBLE_VAULT") else []
        for m in re.finditer(r"!vault \|\n((?:[ \t]+\S.*\n?)+)", s):
            blocks.append("\n".join(l.strip() for l in m.group(1).splitlines()) + "\n")
        for b in blocks:
            n += 1; open(os.path.join(root, ".lab-vault-%d.txt" % n), "w").write(b)
print(n)
PY
opens() {   # opens <old|new> <payload file>
  docker exec -u ops -w /tmp -e ANSIBLE_CONFIG=/ci/.lab-empty.cfg "$CTL" ansible-vault view --vault-password-file "/ci/.lab-$1.sh" "/ci/$2" >/dev/null 2>&1
}
all_new_none_old() {
  local f n=0
  for f in "$CI"/.lab-vault-*.txt; do
    [ -e "$f" ] || continue; n=$((n+1))
    opens new "${f##*/}" || { echo "not with new: $f" >> "$VERIFY_LOG"; return 1; }
    opens old "${f##*/}" && { echo "still opens with old: $f" >> "$VERIFY_LOG"; return 1; }
  done
  [ $n -ge 3 ]
}
no_pw_files() { ! grep -rlF -e "$(recall old_vault)" -e "$(recall new_vault)" "$CI" --exclude-dir=.git --exclude='.lab-*' | grep . >> "$VERIFY_LOG"; }
check ".vault_pass is not tracked and is git-ignored" eval '! git -C "$CI" ls-files --error-unmatch .vault_pass >/dev/null 2>&1 && git -C "$CI" check-ignore -q .vault_pass'
check "every vaulted value opens with the new password, none with the old" all_new_none_old
check "no vault password in any file" no_pw_files
check "site.yml converges" converged site.yml
check "web1's credentials unchanged" eval 'nx web1 "cat /etc/acme/app.env" | grep -qx "SMTP_PASSWORD=$(recall smtp)" && nx web1 "cat /etc/acme/app.env" | grep -qx "API_KEY=$(recall key)"'
verdict
