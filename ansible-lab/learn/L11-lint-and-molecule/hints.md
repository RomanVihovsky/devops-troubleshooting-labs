## Hint 1
Typical findings: `fqcn[action-core]` -> `ansible.builtin.package`; `name[casing]` -> names start with a capital;
`yaml[truthy]` -> `true`/`false`; `risky-file-permissions` -> give templates a `mode`; `no-free-form` -> use
YAML arguments instead of `key=value` strings; `var-naming[no-role-prefix]` -> role variables start with the role name. `ansible-lint -L` lists rules, `--fix` auto-fixes some.

## Hint 2
```yaml
# molecule/default/molecule.yml
driver: {name: default, options: {managed: false}}
platforms: [{name: test1}]
provisioner:
  name: ansible
  inventory: {hosts: {all: {hosts: {test1: {ansible_host: test1, ansible_user: ansible}}}}}
scenario: {test_sequence: [syntax, converge, idempotence, verify]}
verifier: {name: ansible}
```

## Hint 3
`verify.yml`: `ansible.builtin.command: sshd -T` (`become: true`, `changed_when: false`), register, then
`ansible.builtin.assert` that `'passwordauthentication no' in r.stdout_lines` and the same for `permitrootlogin no`.
`converge.yml` just applies the role to `all` with `become: true`. Run with `ANSIBLE_ROLES_PATH` pointing at `roles/`.
