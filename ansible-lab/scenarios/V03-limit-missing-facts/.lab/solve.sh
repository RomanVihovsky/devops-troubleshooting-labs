python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""- name: Web
  hosts: web
  become: true
  tasks:""", """- name: Web
  hosts: web
  become: true
  pre_tasks:
    - name: Facts about the database hosts (they may be outside --limit)
      ansible.builtin.setup:
        gather_subset: [network]
      delegate_to: "{{ item }}"
      delegate_facts: true
      loop: "{{ groups['db'] }}"
      when: hostvars[item]['ansible_facts']['all_ipv4_addresses'] is not defined
  tasks:""")
open(p, "w").write(s)
PY
run_logged "$SETUP_LOG" ctl "ansible-playbook site.yml --limit web"
