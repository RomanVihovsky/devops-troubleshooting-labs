cat > deploy.yml <<'YML'
# usage: ansible-playbook deploy.yml -e app_release=<version>
# One node at a time, out of the load balancer while it changes; stop at the first failure.
- name: Deploy a release
  hosts: web
  become: true
  serial: 1
  max_fail_percentage: 0
  vars_files:
    - "releases/{{ app_release }}.yml"

  pre_tasks:
    - name: Drain from the load balancer
      community.general.haproxy:
        state: disabled
        backend: web
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

    - name: Restart now if needed
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
        backend: web
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
