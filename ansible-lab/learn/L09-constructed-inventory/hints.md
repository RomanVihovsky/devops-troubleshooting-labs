## Hint 1
```yaml
plugin: ansible.builtin.constructed
strict: true
keyed_groups:
  - key: env
    prefix: env
```
The default separator is `_` -> `env_prod`.

## Hint 2
`groups:` maps a group name to a Jinja **expression** (no `{{ }}`): `critical: tier == 'gold'`.

## Hint 3
Patterns: `env_prod:&role_web` = intersection; `web:!db` = difference; `all:!critical`.
`ansible-playbook patch.yml --list-hosts` before you run it.
