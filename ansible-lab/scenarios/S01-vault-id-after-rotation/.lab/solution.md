# Solution - give Ansible every vault secret it needs

**Root cause**: after the rotation the prod file is encrypted with a new password (vault ID `prod`), but the
repo still hands Ansible only the old shared password (`vault_password_file`). Ansible tries all secrets it
knows; none opens the prod file.

**Fix**: a vault password **client script** (name ends in `-client`; called with `--vault-id <label>`) that
maps labels to CI secrets, and `vault_identity_list = default@..., prod@...` in ansible.cfg.

**Interview notes**
* Vault ID labels are hints: by default Ansible tries the matching label first, then all others
  (`vault_id_match = True` makes it strict).
* `ansible-vault rekey --new-vault-id prod@...` changes password and label; `encrypt --encrypt-vault-id prod`
  picks the ID when several are configured.
* Separate passwords per environment limit the blast radius of a leak - that's why security rotated prod only.
* Never `echo $PASSWORD > file` in CI; client scripts read the secret store / env at run time.
