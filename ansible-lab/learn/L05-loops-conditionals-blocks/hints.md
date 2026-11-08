## Hint 1
`loop: "{{ team }}"`, then `item.name`, `item.state`. `loop_control: {label: "{{ item.name }}"}`.
Admin group: `"{{ 'wheel' if ansible_facts['os_family'] == 'RedHat' else 'sudo' }}"`.

## Hint 2
`ansible.builtin.user` with `state: "{{ item.state }}"` and `remove: true` handles both directions in one task.
`groups` only matters for present users.

## Hint 3
```yaml
- block:
    - ansible.builtin.package: {name: acme-agent, state: present}
  rescue:
    - ansible.builtin.copy: {dest: /etc/acme/agent-missing, content: "not in mirror\n", mode: "0644"}
  always:
    - ansible.builtin.file: {path: /etc/acme, state: directory, mode: "0755"}
```
Careful with order: the rescue needs the directory. `changed_when: false` on the command.
