cat > users.yml <<'YML'
- name: Team accounts
  hosts: web
  become: true
  tasks:
    - name: Team users
      ansible.builtin.user:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
        remove: "{{ item.state == 'absent' }}"
        shell: /bin/bash
        groups: "{{ [admin_group] if item.admin else [] }}"
      loop: "{{ team }}"
      loop_control:
        label: "{{ item.name }}"
      vars:
        admin_group: "{{ 'wheel' if ansible_facts['os_family'] == 'RedHat' else 'sudo' }}"

    - name: Optional monitoring agent
      block:
        - name: Install acme-agent
          ansible.builtin.package:
            name: acme-agent
            state: present
      rescue:
        - name: Note that the agent is missing
          ansible.builtin.copy:
            dest: /etc/acme/agent-missing
            content: "acme-agent is not in the mirror\n"
            mode: "0644"
      always:
        - name: Config directory
          ansible.builtin.file:
            path: /etc/acme
            state: directory
            mode: "0755"

    - name: Count local users
      ansible.builtin.command: getent passwd
      register: passwd
      changed_when: false

    - name: Report
      ansible.builtin.debug:
        msg: "{{ passwd.stdout_lines | length }} local users"
YML
sed -i 's|    - name: Optional monitoring agent|    - name: Config directory first\n      ansible.builtin.file:\n        path: /etc/acme\n        state: directory\n        mode: "0755"\n\n    - name: Optional monitoring agent|' users.yml
ap users.yml
