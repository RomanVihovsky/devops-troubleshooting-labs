cat > site.yml <<'YML'
---
- name: Web node
  hosts: web
  become: true
  vars:
    app_port: 8080
    start_nginx: true
  tasks:
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Config directory
      ansible.builtin.file:
        path: /etc/acme
        state: directory
        mode: "0755"

    - name: Deploy app config
      ansible.builtin.copy:
        dest: /etc/acme/app.conf
        content: "port={{ app_port }}\n"
        mode: "0644"
      notify: Reload nginx

    - name: Ensure nginx running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
      when: start_nginx

  handlers:
    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
YML
run_logged "$SETUP_LOG" ctl "sh ci/lint.sh"
ap site.yml
