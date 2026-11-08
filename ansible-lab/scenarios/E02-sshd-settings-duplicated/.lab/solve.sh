mkdir -p templates && cp "$SCN/.lab/fix/10-acme.conf.j2" templates/
python3 - <<'PY'
p = "site.yml"
s = open(p).read()
a = s[s.index("    - name: sshd settings\n"):s.index("  handlers:")]
s = s.replace(a, """    - name: sshd settings (drop-in, included first - first value wins)
      ansible.builtin.template:
        src: templates/10-acme.conf.j2
        dest: /etc/ssh/sshd_config.d/10-acme.conf
        mode: "0644"
      notify: Reload sshd
    - name: Managed settings out of the main file
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^{{ item.key }}\\\\s"
        state: absent
      loop: "{{ sshd_settings | dict2items }}"
      notify: Reload sshd
""")
open(p, "w").write(s)
PY
ap site.yml
