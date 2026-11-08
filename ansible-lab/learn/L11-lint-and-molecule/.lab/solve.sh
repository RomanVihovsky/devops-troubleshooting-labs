cat > roles/sshd_hardening/tasks/main.yml <<'YML'
- name: Install the OpenSSH server
  ansible.builtin.package:
    name: openssh-server
    state: present

- name: Hardening snippet
  ansible.builtin.template:
    src: hardening.conf.j2
    dest: /etc/ssh/sshd_config.d/50-acme.conf
    mode: "0644"
    validate: /usr/sbin/sshd -t -f %s
  notify: Reload sshd

- name: Sshd running
  ansible.builtin.service:
    name: "{{ sshd_hardening_service }}"
    state: started
    enabled: true
YML
cat > roles/sshd_hardening/handlers/main.yml <<'YML'
- name: Reload sshd
  ansible.builtin.service:
    name: "{{ sshd_hardening_service }}"
    state: reloaded
YML
echo 'sshd_hardening_service: ssh' > roles/sshd_hardening/defaults/main.yml
m=roles/sshd_hardening/molecule/default
mkdir -p $m
cat > $m/molecule.yml <<'YML'
driver:
  name: default
  options:
    managed: false
platforms:
  - name: test1
provisioner:
  name: ansible
  inventory:
    hosts:
      all:
        hosts:
          test1:
            ansible_host: test1
            ansible_user: ansible
scenario:
  test_sequence:
    - syntax
    - converge
    - idempotence
    - verify
verifier:
  name: ansible
YML
cat > $m/converge.yml <<'YML'
- name: Converge
  hosts: all
  become: true
  roles:
    - sshd_hardening
YML
cat > $m/verify.yml <<'YML'
- name: Verify
  hosts: all
  become: true
  gather_facts: false
  tasks:
    - name: Effective sshd configuration
      ansible.builtin.command: sshd -T
      register: sshd_hardening_effective
      changed_when: false

    - name: Hardening is effective
      ansible.builtin.assert:
        that:
          - "'passwordauthentication no' in sshd_hardening_effective.stdout_lines"
          - "'permitrootlogin no' in sshd_hardening_effective.stdout_lines"
YML
run_logged "$SETUP_LOG" ctl "cd roles/sshd_hardening && ANSIBLE_ROLES_PATH=/work/roles molecule test"
