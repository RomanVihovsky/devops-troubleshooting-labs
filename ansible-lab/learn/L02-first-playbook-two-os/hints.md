## Hint 1
A play: `- name: ... hosts: web become: true tasks: [...] handlers: [...]`. Use FQCNs:
`ansible.builtin.package`, `ansible.builtin.template`, `ansible.builtin.service`.

## Hint 2
Facts: `{{ ansible_facts['hostname'] }}`, `{{ ansible_facts['distribution'] }}`,
`{{ ansible_facts['distribution_major_version'] }}`. (The old `ansible_distribution` style is deprecated - see L13.)

## Hint 3
Template task with `notify: Reload nginx`; a handler `ansible.builtin.service: name=nginx state=reloaded`;
then `ansible.builtin.service: name=nginx state=started enabled=true`.
