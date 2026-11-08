## Hint 1
Find every vaulted thing: `grep -rl '^\$ANSIBLE_VAULT' .` (whole files) and `grep -rn '!vault' .` (inline strings).
`ansible-vault rekey` handles whole files only.

## Hint 2
A script can be a password source: `ci/vault-pass.sh` printing `$ACME_VAULT_PASSWORD`. Files:
`ansible-vault rekey --new-vault-password-file ci/vault-pass.sh <files>` (the old password comes from ansible.cfg).
Inline strings: read the value first (`ansible-vault view` works on a file holding just the `$ANSIBLE_VAULT`
block without indentation), switch ansible.cfg to the new script, then `ansible-vault encrypt_string ... --name smtp_password`.
Order matters: with both passwords configured, `encrypt_string` refuses ("vault-ids default,default").

## Hint 3
`sed -n '/!vault/,$p' group_vars/all/main.yml | tail -n +2 | sed 's/^ *//' > /tmp/smtp.vault; ansible-vault view /tmp/smtp.vault`.
Then: `vault_password_file = ci/vault-pass.sh`, `git rm --cached .vault_pass`, delete it, add it to `.gitignore`.
The old password is still in git history - which is why rotating (not just deleting) is the fix.
