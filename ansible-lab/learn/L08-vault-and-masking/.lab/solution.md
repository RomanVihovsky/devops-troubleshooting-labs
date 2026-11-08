# Solution - L08

Reference: `.lab/solve.sh`.
```ini
vault_identity_list = prod@vault-pass.sh
```
```yaml
- ansible.builtin.slurp: {src: /etc/acme/bootstrap-token}
  register: token_raw
  no_log: true
- ansible.builtin.set_fact:
    api_token: "{{ (token_raw.content | b64decode | trim) | ansible.builtin.register_secret }}"
- ansible.builtin.template: {src: templates/app.env.j2, dest: /etc/acme/app.env, mode: "0600"}
  diff: false
```

**Takeaways**
* Vault IDs label secrets per environment (`dev@`, `prod@`); the header `$ANSIBLE_VAULT;1.2;AES256;prod`
  shows the label. Password *clients* (scripts) pull the password from a secret store - no files lying around.
* 2.22 secret masking: values from `no_log` options, vault and `register_secret` are masked as `$REDACTED$`
  everywhere Ansible prints (callbacks, debug, logs). `debug` no longer has an opt-out (2.22 porting guide).
* Masking only knows exact strings: base64/hex/JSON-escaped variants still leak -> `no_log` on tasks that *carry*
  secrets, `diff: false` on templates that contain them.
* The plain password is still in git history of this lab's first commit - in real life: rotate it (S03).
