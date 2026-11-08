# Deploy fails since the prod vault password rotation: "Decryption failed (no vault secrets were found that could decrypt)"
**SEC-90** · P1 · Reporter: CI

Security rotated the **prod** vault password yesterday (see `git log`): prod files now use the vault ID `prod`,
the new password is in the CI secret `ACME_VAULT_PROD`. Staging still uses the old shared password
(`ACME_VAULT_DEFAULT`). Both variables are in the CI environment and in your lab shell.

Don't write passwords into files, and don't undo the rotation.

**Test**: site.yml deploys to prod and staging and converges; each environment gets its own DB password; the
prod vault opens with the new password and **not** with the old one; no password in the repo.
