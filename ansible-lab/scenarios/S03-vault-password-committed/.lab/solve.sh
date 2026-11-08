printf '#!/bin/sh\n# vault password from the CI secret store\nprintf "%%s\\n" "${ACME_VAULT_PASSWORD:?not set}"\n' > ci/vault-pass.sh
chmod +x ci/vault-pass.sh
# 1. read the inline secret with the old password (a file holding just the vault block)
sed -n '/!vault/,$p' group_vars/all/main.yml | tail -n +2 | sed 's/^ *//' > .smtp.vault
smtp=$(ctl "ansible-vault view .smtp.vault"); rm -f .smtp.vault
# 2. rekey the vault files
ctl "ansible-vault rekey --new-vault-password-file ci/vault-pass.sh group_vars/all/vault.yml host_vars/web1/vault.yml" >> "$SETUP_LOG" 2>&1
# 3. switch the config to the new source, then re-encrypt the inline string
sed -i 's|^vault_password_file = .vault_pass$|vault_password_file = ci/vault-pass.sh|' ansible.cfg
{ echo "smtp_host: smtp.acme.internal"; ctl "ansible-vault encrypt_string '$smtp' --name smtp_password" 2>>"$SETUP_LOG"; } > group_vars/all/main.yml.new
mv group_vars/all/main.yml.new group_vars/all/main.yml
# 4. the old file out of git
git rm -q --cached .vault_pass; rm -f .vault_pass
printf '.vault_pass\n' >> .gitignore
ap site.yml
