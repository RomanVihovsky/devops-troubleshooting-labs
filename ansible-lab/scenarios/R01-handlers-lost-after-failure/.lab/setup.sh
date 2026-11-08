ap site.yml
ws_commit "shop 2.4.0"
python3 - <<'PY'
p = "site.yml"
s = open(p).read()
s = s.replace("""        enabled: true
  handlers:""", """        enabled: true
    - name: "Smoke: the new version is live"
      ansible.builtin.uri:
        url: http://127.0.0.1:8080/version
        return_content: true
      register: shop_smoke
      failed_when: shop_smoke.content | trim != shop_version
  handlers:""")
open(p, "w").write(s)
PY
sed -i 's/2.4.0/2.4.1/' group_vars/all.yml
ws_commit "release 2.4.1 + smoke check after deploy" "release manager"
ap site.yml || true
ap site.yml || true
