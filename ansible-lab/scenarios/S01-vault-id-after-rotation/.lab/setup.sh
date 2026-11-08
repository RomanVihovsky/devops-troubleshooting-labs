lab_setenv ACME_VAULT_DEFAULT "shared-$(od -An -tx1 -N8 /dev/urandom | tr -d " \n")"
lab_setenv ACME_VAULT_PROD "prod-$(od -An -tx1 -N8 /dev/urandom | tr -d " \n")"
sp="stg-db-$(od -An -tx1 -N8 /dev/urandom | tr -d " \n")"; pp="prod-db-$(od -An -tx1 -N8 /dev/urandom | tr -d " \n")"
remember staging_pw "$sp"; remember prod_pw "$pp"; remember old_vault "$ACME_VAULT_DEFAULT"; remember new_vault "$ACME_VAULT_PROD"
printf 'vault_db_password: "%s"\n' "$sp" > group_vars/staging/vault.yml
printf 'vault_db_password: "%s"\n' "$pp" > group_vars/prod/vault.yml
ctl "ansible-vault encrypt group_vars/staging/vault.yml group_vars/prod/vault.yml" >> "$SETUP_LOG" 2>&1
ap site.yml
ws_commit "per-environment DB passwords in vault"
printf '#!/bin/sh\nprintf "%%s\\n" "$ACME_VAULT_PROD"\n' > .lab-newpw.sh; chmod +x .lab-newpw.sh
ctl "ansible-vault rekey --new-vault-id prod@.lab-newpw.sh group_vars/prod/vault.yml" >> "$SETUP_LOG" 2>&1
rm -f .lab-newpw.sh
ws_commit "security: rotate the prod vault password, vault ID prod (SEC-90)" "security team"
ap site.yml || true
