cat > templates/site.conf.j2 <<'J2'
# managed by Ansible
server {
    listen 8080 default_server;
    root /usr/share/nginx/html;
}
J2
cat > templates/index.html.j2 <<'J2'
Hello from {{ ansible_facts['hostname'] }} running {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_major_version'] }}
J2
cat > site.yml <<'YML'
- name: Web servers
  hosts: web
  become: true
  tasks:
    - name: Install nginx
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Site config
      ansible.builtin.template:
        src: templates/site.conf.j2
        dest: /etc/nginx/conf.d/site.conf
        mode: "0644"
      notify: Reload nginx

    - name: Index page
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: /usr/share/nginx/html/index.html
        mode: "0644"

    - name: Run nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
YML
ap site.yml
