# Solution - a leaked vault password means rekey everything

**Root cause**: `.vault_pass` (the vault password) was committed. Deleting it is not enough: it is in git
history forever (and in every clone). The vault must be re-encrypted with a new password.

**Fix**:
1. `ci/vault-pass.sh` prints `$ACME_VAULT_PASSWORD` (the secret store); `vault_password_file` points to it.
2. `ansible-vault rekey --vault-password-file .vault_pass --new-vault-password-file ci/vault-pass.sh` for every
   vault **file**.
3. Inline `!vault` strings are not touched by `rekey`: decrypt and `encrypt_string` them again.
4. `git rm --cached .vault_pass`, delete it, git-ignore it.
5. Follow-up (separate ticket): rotate the secrets themselves - they were readable with the old password.

**Interview notes**
* Rewriting history (`git filter-repo`) is hygiene, not remediation: forks and clones keep the old commits.
* Pre-commit hooks / secret scanners (gitleaks, trufflehog) catch `.vault_pass`-style files.
* Prefer whole vault files (`vault.yml` + `vault_` prefix indirection) over many inline strings - rekeyable.
* Watch out with weak vault passwords on 2.22: masking replaces every occurrence of the password text in
  output (a vault password `pass` turns `password` into `$REDACTED$word`).
