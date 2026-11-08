## Hint 1
`ansible web -m ansible.builtin.command -a id -b -K` works interactively - so it's only about *giving* Ansible
the password. The connection variable is `ansible_become_password`.

## Hint 2
`group_vars/all/vault.yml` with `vault_become_password: ...` encrypted with
`ansible-vault encrypt --encrypt-vault-id prod`, plus `group_vars/all/vars.yml`:
`ansible_become_password: "{{ vault_become_password }}"` (the indirection keeps vars greppable).

## Hint 3
`vault-pass.sh` prints `$ACME_VAULT_PROD`; `ansible.cfg`: `vault_identity_list = prod@vault-pass.sh`.
Then `ansible-playbook site.yml` needs no flags.
