cat > ansible.cfg <<'CFG'
[defaults]
inventory = inventory/hosts.yml
remote_user = ansible
host_key_checking = True
interpreter_python = auto_silent
callbacks_enabled = ansible.posix.profile_tasks, ansible.posix.timer
gathering = smart
fact_caching = ansible.builtin.jsonfile
fact_caching_connection = /tmp/ansible-facts
fact_caching_timeout = 3600

[ssh_connection]
# ssh_args left at the default: -C -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
CFG
python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = """- name: sshd without reverse DNS (root cause of the slowness)
  hosts: web
  become: true
  tasks:
    - name: UseDNS off
      ansible.builtin.copy:
        dest: /etc/ssh/sshd_config.d/10-dns.conf
        content: "UseDNS no\\n"
        mode: "0644"
        validate: /usr/sbin/sshd -t -f %s
      notify: Reload sshd
  handlers:
    - name: Reload sshd
      ansible.builtin.service:
        name: "{{ 'sshd' if ansible_facts['os_family'] == 'RedHat' else 'ssh' }}"
        state: reloaded

""" + s
open(p, "w").write(s)
PY
ap site.yml
