cat > group_vars/all.yml <<'YML'
app_name: shop
app_port: 8080
enable_tls: true
enable_motd: true
YML
python3 - <<'PY'
p = "roles/web/tasks/main.yml"
s = open(p).read()
s = s.replace("""      - app_name
      - app_port""", """      - app_name | length > 0
      - app_port | int > 0""")
s = s.replace("failed_when: nginx_test.rc\n", "failed_when: nginx_test.rc != 0\n")
s = s.replace("when: enable_tls\n", "when: enable_tls | bool\n")
s = s.replace("when: enable_motd\n", "when: enable_motd | bool\n")
open(p, "w").write(s)
PY
