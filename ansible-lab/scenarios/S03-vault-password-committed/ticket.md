# The vault password file has been in the repo since 2019
**SEC-95** · P1 · Reporter: security

`.vault_pass` is committed - everyone who can read the repo can decrypt every secret in it. Security created a
new vault password in the CI secret store: `ACME_VAULT_PASSWORD` (also in your lab shell).

Rotating the secrets *inside* the vault is a follow-up ticket - today: the vault itself.

**Test**: `.vault_pass` is no longer tracked and is git-ignored; every vaulted value in the repo - files **and**
inline `!vault` strings - opens with the new password and none with the old one; Ansible reads the password
from the environment (no password in any file); site.yml converges with web1's credentials unchanged.
