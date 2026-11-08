rh() { od -An -tx1 -N8 /dev/urandom | tr -d ' \n'; }
old="Acme2019!$(rh | cut -c1-4)"; remember old_vault "$old"
lab_setenv ACME_VAULT_PASSWORD "new-$(rh)"; remember new_vault "$ACME_VAULT_PASSWORD"
db="db-$(rh)"; key="key-$(rh)"; smtp="smtp-$(rh)"
remember db "$db"; remember key "$key"; remember smtp "$smtp"
printf '%s\n' "$old" > .vault_pass
printf 'vault_db_password: "%s"\n' "$db" > group_vars/all/vault.yml
printf 'vault_api_key: "%s"\n' "$key" > host_vars/web1/vault.yml
ctl "ansible-vault encrypt group_vars/all/vault.yml host_vars/web1/vault.yml" >> "$SETUP_LOG" 2>&1
{ echo "smtp_host: smtp.acme.internal"; ctl "ansible-vault encrypt_string '$smtp' --name smtp_password" 2>>"$SETUP_LOG"; } > group_vars/all/main.yml
ap site.yml
ws_commit "app secrets (2019 setup)"
