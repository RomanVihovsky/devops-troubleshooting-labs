cat > inventory/02-constructed.yml <<'YML'
plugin: ansible.builtin.constructed
strict: true
keyed_groups:
  - key: env
    prefix: env
  - key: role
    prefix: role
groups:
  critical: tier == 'gold'
YML
cat > patch.yml <<'YML'
- name: Patch marker on prod web servers
  hosts: env_prod:&role_web
  become: true
  tasks:
    - name: Marker
      ansible.builtin.copy:
        dest: /etc/acme/patched
        content: "patched by Ansible\n"
        mode: "0644"
YML
sed -i 's|        dest: /etc/acme/patched|        dest: /etc/acme/patched|' patch.yml
python3 - <<'PY'
p = "patch.yml"
s = open(p).read()
s = s.replace("""  tasks:
    - name: Marker""", """  tasks:
    - name: Directory
      ansible.builtin.file:
        path: /etc/acme
        state: directory
        mode: "0755"

    - name: Marker""")
open(p, "w").write(s)
PY
ap patch.yml
