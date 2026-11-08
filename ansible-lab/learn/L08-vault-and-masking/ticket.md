# L08 · Vault and secret masking (ansible-core 2.22)
**Learn** · vault IDs, password client scripts, `no_log`, `register_secret`, `diff: false` · ~30 min

`site.yml` deploys `/etc/acme/app.env` with a DB password (from `group_vars/web/vault.yml` - still in
**plain text**) and an API token it reads from each node's `/etc/acme/bootstrap-token`. Today both secrets
end up in the job log.

1. Encrypt `group_vars/web/vault.yml` with vault ID **`prod`**. The password is in your environment as
   `ACME_VAULT_PROD` (CI has the same variable). Write `vault-pass.sh` that prints it, and set
   `vault_identity_list = prod@vault-pass.sh` in `ansible.cfg` - no `--vault-password-file` on command lines.
2. The token: Ansible 2.22 masks only values it knows are secrets. Register it with the new
   `ansible.builtin.register_secret` filter where you `set_fact` it - then `debug` shows `$REDACTED$`.
3. Nothing else may print it: the `slurp` result contains it base64-encoded, and `--diff` of the env template
   would show both secrets.

**Test**: the vault file is encrypted with ID `prod`; no plain DB password in the repo; a verbose CI run
(`-v --diff`) prints neither the password, nor the token, nor the token in base64; the nodes' env files hold the
right values; site.yml converges.
