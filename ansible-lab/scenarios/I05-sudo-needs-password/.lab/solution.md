# Solution - become password from Vault

**Root cause**: the hardening removed `NOPASSWD`; Ansible had no become password, so sudo's prompt failed.

**Fix**
```yaml
# group_vars/all/vars.yml
ansible_become_password: "{{ vault_become_password }}"
# group_vars/all/vault.yml (ansible-vault, ID prod)
vault_become_password: <secret>
```
plus `vault_identity_list = prod@vault-pass.sh` (client script reading the CI secret).

**Interview notes**
* `-K` / `--ask-become-pass` for humans; vaulted `ansible_become_password` (per group/host) for automation;
  better still, short-lived credentials from a secret store (HashiCorp Vault lookup) or a dedicated automation
  account with a narrow sudo policy.
* Re-adding NOPASSWD undoes a security control - an audit finding waiting to happen.
* 2.22 masks become passwords like other secrets; keep `no_log` on tasks that template them anyway.
