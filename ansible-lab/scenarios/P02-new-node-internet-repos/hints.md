## Hint 1
`./lab node web2` -> `ls /etc/yum.repos.d/`, `dnf repolist`. Which repos are enabled, and can this network
reach them?

## Hint 2
The node must be told about the mirror **before** the first package task, and the vendor repos must be off - else
dnf still tries them (and fails). That's playbook work (`pre_tasks`), not a manual fix: the next node comes
from the same image.

## Hint 3
`ansible.builtin.yum_repository` with `name: acme-rocky9`, `file: acme`, `baseurl:
http://repo.acme.internal/rocky9`, `gpgcheck: false`; then the same module with `state: absent` for
`baseos`/`appstream` (file `rocky`) and `extras` (file `rocky-extras`). `when: ansible_facts['os_family'] == 'RedHat'`.
