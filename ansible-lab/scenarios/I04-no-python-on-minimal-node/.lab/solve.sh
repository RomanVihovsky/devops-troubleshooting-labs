python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = """- name: Bootstrap Python on minimal nodes
  hosts: all
  gather_facts: false
  become: true
  tasks:
    - name: Python for Ansible
      ansible.builtin.raw: test -e /usr/bin/python3 || (apt-get update -qq && apt-get install -y -qq python3 python3-apt)
      register: py
      changed_when: "'Setting up python3' in py.stdout"

""" + s
open(p, "w").write(s)
PY
ap site.yml
