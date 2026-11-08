python3 - <<'PY'
p = "backup.yml"
s = open(p).read()
s = s.replace("""      async: 600
      poll: 0
      changed_when: true
""", """      async: 600
      poll: 0
      changed_when: true
      register: dump_job
    - name: Wait for the dump to finish
      ansible.builtin.async_status:
        jid: "{{ dump_job.ansible_job_id }}"
      register: dump_result
      until: dump_result.finished
      retries: 120
      delay: 3
""")
open(p, "w").write(s)
PY
grep -q async_status backup.yml
ap backup.yml
