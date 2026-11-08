python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""      ansible.builtin.copy:
        dest: /etc/motd
        content: "{{ lookup('ansible.builtin.file', 'templates/motd.j2') }}\\n"
""", """      ansible.builtin.template:
        src: templates/motd.j2
        dest: /etc/motd
""")
open(p, "w").write(s)
PY
grep -q 'ansible.builtin.template' site.yml
ap site.yml
