python3 - <<'PY'
p = "deploy.yml"
s = open(p).read()
s = s.replace("""    - name: Token for the smoke test
      ansible.builtin.debug:
        msg: "SMOKE_TOKEN={{ api_token }}"
""", """    - name: Token for the smoke test (file, not stdout)
      ansible.builtin.copy:
        dest: "{{ playbook_dir }}/.ci/smoke-token"
        content: "{{ api_token }}"
        mode: "0600"
""")
open(p, "w").write(s)
p = "ci/pipeline.sh"
s = open(p).read()
s = s.replace("""TOKEN=$(sed -n 's/.*"msg": "SMOKE_TOKEN=\\(.*\\)"$/\\1/p' .ci/deploy.log)""", "TOKEN=$(cat .ci/smoke-token)")
s = s.replace('echo "smoke test passed"', 'rm -f .ci/smoke-token\necho "smoke test passed"')
open(p, "w").write(s)
PY
grep -q 'cat .ci/smoke-token' ci/pipeline.sh
ctl "sh ci/pipeline.sh" >> "$SETUP_LOG" 2>&1
