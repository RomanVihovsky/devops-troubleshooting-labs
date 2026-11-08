python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""  tasks:
    - name: Service account""", """  tasks:
    - name: ACL support (Ansible needs setfacl to become an unprivileged user)
      ansible.builtin.package:
        name: acl
        state: present

    - name: Service account""")
open(p, "w").write(s)
PY
ap site.yml
