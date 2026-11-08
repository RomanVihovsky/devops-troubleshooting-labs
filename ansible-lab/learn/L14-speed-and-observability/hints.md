## Hint 1
`time ssh ansible@web2 true` from the controller - then `time ssh -o ControlMaster=no ansible@web2 true`.
Every new SSH connection to these nodes costs seconds (their sshd does reverse DNS against a dead resolver).
With `ControlMaster=no` *every* task pays it, several times.

## Hint 2
Ansible's default `ssh_args` are `-C -o ControlMaster=auto -o ControlPersist=60s`. Overriding `ssh_args`
replaces them completely - delete the override or restore those options.

## Hint 3
```ini
[defaults]
callbacks_enabled = ansible.posix.profile_tasks, ansible.posix.timer
gathering = smart
fact_caching = ansible.builtin.jsonfile
fact_caching_connection = /tmp/ansible-facts
fact_caching_timeout = 3600
[ssh_connection]
pipelining = True
```

## Hint 4 (root cause)
```yaml
- name: sshd without reverse DNS
  hosts: web
  become: true
  tasks:
    - ansible.builtin.copy:
        dest: /etc/ssh/sshd_config.d/10-dns.conf
        content: "UseDNS no\n"
        mode: "0644"
        validate: /usr/sbin/sshd -t -f %s
      notify: Reload sshd
  handlers:
    - name: Reload sshd
      ansible.builtin.service:
        name: "{{ 'sshd' if ansible_facts['os_family'] == 'RedHat' else 'ssh' }}"
        state: reloaded
```
