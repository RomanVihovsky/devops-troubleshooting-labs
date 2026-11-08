# Every play fails: "Missing sudo password" after the CIS hardening
**SEC-372** · P2 · Reporter: platform

Security's hardening run removed `NOPASSWD` for the `ansible` account on all web nodes; sudo now asks for the
account's password. Every `become: true` play fails with `Missing sudo password`. The new password is in the
password manager - for this lab: `$ACME_BECOME_PASSWORD` in your shell. CI has a vault password as
`$ACME_VAULT_PROD`.

Give Ansible the become password **from Ansible Vault** (vault ID `prod`, password client script, like everywhere
else). Do **not** re-add `NOPASSWD` on the nodes, and no plaintext password in the repo or on command lines.

**Test**: site.yml converges non-interactively; the become password lives in a vault-encrypted file (ID `prod`);
no plaintext password in the repo; sudo on the nodes still requires a password.
