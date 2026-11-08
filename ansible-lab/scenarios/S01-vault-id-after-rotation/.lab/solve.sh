cat > ci/vault-pass-client.sh <<'SH'
#!/bin/sh
# vault password client: called as  vault-pass-client.sh --vault-id <label>
case "${2:-default}" in
  prod) printf '%s\n' "${ACME_VAULT_PROD:?not set}" ;;
  *)    printf '%s\n' "${ACME_VAULT_DEFAULT:?not set}" ;;
esac
SH
chmod +x ci/vault-pass-client.sh
sed -i 's|^vault_password_file = ci/vault-pass.sh$|vault_identity_list = default@ci/vault-pass-client.sh, prod@ci/vault-pass-client.sh|' ansible.cfg
git rm -q ci/vault-pass.sh
ap site.yml
