## Hint 1
Almost every module is Python code executed **on the managed node**. Which module does not need Python at all?
(It is also how you would install Python in the first place.)

## Hint 2
A first play with `gather_facts: false` (fact gathering is a Python module too) and `ansible.builtin.raw` -
plain shell over SSH. Make it idempotent: only install when Python is missing.

## Hint 3
```yaml
- name: Bootstrap Python
  hosts: all
  gather_facts: false
  become: true
  tasks:
    - name: Python for Ansible
      ansible.builtin.raw: test -e /usr/bin/python3 || (apt-get update -qq && apt-get install -y -qq python3 python3-apt)
      register: py
      changed_when: "'Setting up python3' in py.stdout"
```
