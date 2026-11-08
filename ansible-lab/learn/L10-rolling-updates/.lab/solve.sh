cat > deploy.yml <<'YML'
# usage: ansible-playbook deploy.yml -e app_release=<version>
- name: Database migration (once per deploy)
  hosts: db
  become: true
  tasks:
    - name: Record the migration
      ansible.builtin.lineinfile:
        path: /var/lib/acme/migrations.log
        line: "migrate to {{ app_release }}"
        create: true
        mode: "0644"

- name: Roll the app tier
  hosts: app
  become: true
  serial: 1
  max_fail_percentage: 0

  pre_tasks:
    - name: Drain from the load balancer
      community.general.haproxy:
        state: disabled
        backend: app
        host: "{{ inventory_hostname }}"
        socket: /run/haproxy/admin.sock
      delegate_to: lb1

  tasks:
    - name: Release marker
      ansible.builtin.copy:
        dest: /usr/share/nginx/html/version.txt
        content: "{{ app_release }}\n"
        mode: "0644"

    - name: App config
      ansible.builtin.template:
        src: templates/app.conf.j2
        dest: /etc/nginx/conf.d/app.conf
        mode: "0644"
      notify: Restart nginx

    - name: Restart now (inside this batch)
      ansible.builtin.meta: flush_handlers

    - name: Wait until healthy
      ansible.builtin.uri:
        url: "http://{{ inventory_hostname }}:8080/health"
      register: health
      until: health.status == 200
      retries: 10
      delay: 1
      delegate_to: lb1

  post_tasks:
    - name: Back into the load balancer
      community.general.haproxy:
        state: enabled
        backend: app
        host: "{{ inventory_hostname }}"
        socket: /run/haproxy/admin.sock
        wait: true
      delegate_to: lb1

  handlers:
    - name: Restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
YML
