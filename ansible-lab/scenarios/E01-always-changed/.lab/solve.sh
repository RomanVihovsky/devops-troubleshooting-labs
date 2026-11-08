python3 - <<'PY'
p = "site.yml"
s = open(p).read()
rep = {
"""      ansible.builtin.shell: id acme || useradd --system --shell /usr/sbin/nologin acme
""": """      ansible.builtin.user:
        name: acme
        system: true
        shell: /usr/sbin/nologin
        create_home: false
""",
"""      ansible.builtin.command: mkdir -p /opt/acme/current
""": """      ansible.builtin.file:
        path: /opt/acme/current
        state: directory
        mode: "0755"
""",
"""      ansible.builtin.command: tar -xzf /opt/acme/release-1.0.tar.gz -C /opt/acme/current
""": """      ansible.builtin.unarchive:
        src: /opt/acme/release-1.0.tar.gz
        dest: /opt/acme/current
        remote_src: true
        creates: /opt/acme/current/VERSION
""",
"""      ansible.builtin.shell: ln -sf /etc/acme/app.conf /etc/acme/enabled.conf
""": """      ansible.builtin.file:
        src: /etc/acme/app.conf
        dest: /etc/acme/enabled.conf
        state: link
""",
"""      register: e01_kernel
""": """      register: e01_kernel
      changed_when: false
""",
}
for a, b in rep.items():
    assert a in s, a
    s = s.replace(a, b)
open(p, "w").write(s)
PY
run_logged "$SETUP_LOG" ctl "sh ci/idempotence.sh"
