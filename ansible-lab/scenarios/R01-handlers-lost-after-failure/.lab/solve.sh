python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""    - name: "Smoke: the new version is live\"""", """    - name: Apply pending config before the smoke check
      ansible.builtin.meta: flush_handlers
    - name: "Smoke: the new version is live\"""")
s = s.replace("  become: true\n  tasks:", "  become: true\n  force_handlers: true\n  tasks:", 1)
open(p, "w").write(s)
PY
grep -q flush_handlers site.yml
run_logged "$SETUP_LOG" ctl "ansible web -b -m ansible.builtin.service -a 'name=nginx state=reloaded'"
ap site.yml
