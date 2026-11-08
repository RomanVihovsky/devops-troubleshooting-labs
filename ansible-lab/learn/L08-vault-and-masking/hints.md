## Hint 1
The script just needs `#!/bin/sh` + `echo "$ACME_VAULT_PROD"` and the executable bit. With
`vault_identity_list = prod@vault-pass.sh` in `ansible.cfg`, encrypt with
`ansible-vault encrypt --encrypt-vault-id prod group_vars/web/vault.yml` (adding `--vault-id prod@...` on top
makes the ID ambiguous: "vault-ids prod,prod are available"). The header then reads `$ANSIBLE_VAULT;1.2;AES256;prod`.

## Hint 2
`api_token: "{{ (token_raw.content | b64decode | trim) | ansible.builtin.register_secret }}"`.
Registration is non-destructive: the value still works everywhere, it is just masked in output.

## Hint 3
`no_log: true` on the `slurp` task (its result *is* the secret), `diff: false` on the template task. Test:
`ansible-playbook site.yml -v --diff | grep -c <the token>` -> 0.
