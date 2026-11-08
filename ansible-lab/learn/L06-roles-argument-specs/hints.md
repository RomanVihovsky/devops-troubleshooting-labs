## Hint 1
```yaml
argument_specs:
  main:
    short_description: ACME app environment file
    options:
      appconfig_port: {type: int, required: true}
      appconfig_mode: {type: str, choices: [dev, prod], default: prod}
      appconfig_features: {type: list, elements: str, default: []}
```

## Hint 2
```yaml
- name: OS-specific variables
  ansible.builtin.include_vars: "{{ lookup('ansible.builtin.first_found', params) }}"
  vars:
    params:
      files: ["{{ ansible_facts['os_family'] }}.yml", default.yml]
      paths: ["{{ role_path }}/vars"]
```

## Hint 3
Template content: `ACME_PORT={{ appconfig_port }}`, `ACME_MODE=...`,
`ACME_FEATURES={{ appconfig_features | join(',') }}`. Test validation with
`ansible-playbook site.yml -e appconfig_mode=chaos` - it must fail before any task runs.
