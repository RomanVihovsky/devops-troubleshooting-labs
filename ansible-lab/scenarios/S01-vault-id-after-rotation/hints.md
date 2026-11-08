## Hint 1
`head -1 group_vars/*/vault.yml` - the header shows format 1.2 and the vault ID label of the prod file.
`ansible-config dump --only-changed | grep -i vault`: which passwords does Ansible know?

## Hint 2
Ansible tries every vault secret it was given. It was given one (`vault_password_file` -> `ACME_VAULT_DEFAULT`).
Give it the prod one too: `vault_identity_list` in ansible.cfg (`label@source`, comma-separated).

## Hint 3
A *client script* (file name ending in `-client`, e.g. `ci/vault-pass-client.sh`) is called with
`--vault-id <label>` and can print the right env variable per label. Then
`vault_identity_list = default@ci/vault-pass-client.sh, prod@ci/vault-pass-client.sh`.
