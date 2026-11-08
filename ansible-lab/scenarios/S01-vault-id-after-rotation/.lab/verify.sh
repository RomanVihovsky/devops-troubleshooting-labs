pwfile() { printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "$2" > "$CI/.lab-$1.sh"; chmod +x "$CI/.lab-$1.sh"; }
pwfile old "$(recall old_vault)"; pwfile new "$(recall new_vault)"
printf "[defaults]\n" > "$CI/.lab-empty.cfg"   # ANSIBLE_CONFIG=/dev/null is rejected by 2.22
opens_with() { docker exec -u ops -w /tmp -e ANSIBLE_CONFIG=/ci/.lab-empty.cfg "$CTL" ansible-vault view --vault-password-file "/ci/.lab-$1.sh" /ci/group_vars/prod/vault.yml >/dev/null 2>&1; }
no_pw_in_repo() { ! grep -rlF -e "$(recall old_vault)" -e "$(recall new_vault)" -e "$(recall prod_pw)" -e "$(recall staging_pw)" "$CI" --exclude-dir=.git --exclude='.lab-*' | grep . >> "$VERIFY_LOG"; }
check "site.yml deploys to prod and staging" applies site.yml
check "web1 (prod) has the prod DB password" eval 'nx web1 "cat /etc/acme/db.env" | grep -qx "DB_PASSWORD=$(recall prod_pw)"'
check "web3 (staging) has the staging DB password" eval 'nx web3 "cat /etc/acme/db.env" | grep -qx "DB_PASSWORD=$(recall staging_pw)"'
check "prod vault opens with the new password" opens_with new
check "prod vault does NOT open with the old password" not opens_with old
check "no password in the repo" no_pw_in_repo
check "site.yml converges" converged site.yml
verdict
