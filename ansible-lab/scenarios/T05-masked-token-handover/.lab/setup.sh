lab_setenv ACME_VAULT_PASSWORD "acme-$(od -An -tx1 -N8 /dev/urandom | tr -d ' \n')"
tok="tok-$(od -An -tx1 -N12 /dev/urandom | tr -d ' \n')"
remember token "$tok"
printf 'vault_api_token: "%s"\n' "$tok" > group_vars/all/vault.yml
ctl "ansible-vault encrypt group_vars/all/vault.yml" >> "$SETUP_LOG" 2>&1
ap deploy.yml
ws_commit "api gateway + smoke test handover"
ctl "sh ci/pipeline.sh" >> "$SETUP_LOG" 2>&1 || true      # 401 since the upgrade
