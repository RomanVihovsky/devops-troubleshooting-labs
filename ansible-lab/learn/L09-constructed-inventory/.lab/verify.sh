members() { ctl_ci "ansible-inventory --list" 2>>"$VERIFY_LOG" | jq -c --arg g "$1" '(.[$g].hosts // []) | sort'; }
groups_ok() {
  [ "$(members env_prod)" = '["app1","db1","web1"]' ] && [ "$(members env_staging)" = '["web2"]' ] &&
  [ "$(members role_web)" = '["web1","web2"]' ] && [ "$(members role_app)" = '["app1"]' ] &&
  [ "$(members role_db)" = '["db1"]' ] && [ "$(members critical)" = '["db1"]' ]
}
markers_ok() {
  nx web1 "test -f /etc/acme/patched" && ! nx web2 "test -f /etc/acme/patched" &&
    ! nx app1 "test -f /etc/acme/patched" && ! nx db1 "test -f /etc/acme/patched"
}
follows_cmdb() {
  sed -i 's/web2: {env: staging/web2: {env: prod/' "$CI/inventory/01-cmdb.yml"
  ap_json patch.yml --check; local rc=$?
  sed -i 's/web2: {env: prod/web2: {env: staging/' "$CI/inventory/01-cmdb.yml"
  [ $rc -eq 0 ] && jq -e '.stats | has("web2") and has("web1") and (has("app1") | not)' "$CI/.lab-ap.json" >/dev/null
}
check "constructed groups with the right members" groups_ok
check "only prod web servers carry /etc/acme/patched" markers_ok
check "patch.yml converges" converged patch.yml
check "a host moved to prod in the CMDB is targeted automatically" follows_cmdb
verdict
