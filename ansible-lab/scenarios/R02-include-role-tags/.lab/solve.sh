python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""      ansible.builtin.include_role:
        name: app
""", """      ansible.builtin.include_role:
        name: app
        apply:
          tags: [deploy]
""")
open(p, "w").write(s)
PY
grep -q 'apply:' site.yml
run_logged "$SETUP_LOG" ctl "sh ci/release.sh"
