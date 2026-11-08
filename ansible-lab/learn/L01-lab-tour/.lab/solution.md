# Solution - L01

```yaml
# inventory/hosts.yml
all:
  children:
    web:
      hosts: {web1: , web2: }
      vars: {tier: frontend}
```
```ini
[defaults]
inventory = inventory/hosts.yml
remote_user = ansible
forks = 20
```
`ansible web -b -m ansible.builtin.user -a "name=deploy shell=/bin/bash"`

**Takeaways**
* Config precedence: `ANSIBLE_CONFIG` env > `./ansible.cfg` > `~/.ansible.cfg` > `/etc/ansible/ansible.cfg`;
  a world-writable cwd is ignored for security (I02). `ansible-config dump --only-changed` shows what is active.
* `ansible-inventory --graph/--list/--host` is the truth about groups and variables.
* Ad-hoc commands use the same modules as playbooks: idempotent modules report `ok` on re-runs.
* 2.22 housekeeping: `-o`/oneline and `tree` callbacks are deprecated (removed in 2.23).
