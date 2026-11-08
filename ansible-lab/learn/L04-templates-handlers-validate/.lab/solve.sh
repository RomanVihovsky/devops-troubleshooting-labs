cat > templates/haproxy.cfg.j2 <<'J2'
# managed by Ansible
global
    maxconn {{ haproxy_maxconn }}
    stats socket /run/haproxy/admin.sock mode 660 level admin

defaults
    mode http
    timeout connect 2s
    timeout client 10s
    timeout server 10s

frontend site
    bind *:80
    default_backend web

backend web
    balance {{ haproxy_balance }}
    option httpchk GET /health
{% for h in groups['web'] %}
    server {{ h }} {{ h }}:8080 check inter 1s
{% endfor %}
J2
cat >> site.yml <<'YML'
- name: Load balancer
  hosts: lb
  become: true
  tasks:
    - name: Install haproxy
      ansible.builtin.package:
        name: haproxy
        state: present
    - name: haproxy config
      ansible.builtin.template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        mode: "0644"
        validate: haproxy -c -f %s
      notify: Reload haproxy
    - name: Run haproxy
      ansible.builtin.service:
        name: haproxy
        state: started
        enabled: true
  handlers:
    - name: Reload haproxy
      ansible.builtin.service:
        name: haproxy
        state: reloaded
YML
ap site.yml
