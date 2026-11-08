workers() { nx "$1" "grep -oP '^workers = \K.*' /etc/acme/appserver.ini" 2>/dev/null; }
overridable() {
  # another team's inventory value must win over the role's own value
  printf 'appserver_timeout: 99\n' >> "$CI/group_vars/web.yml"
  ap_json site.yml --check --diff; local rc=$?
  sed -i '$d' "$CI/group_vars/web.yml"
  [ $rc -eq 0 ] && out_has 'timeout = 99'
}
check "both nodes run with workers = 8" eval '[ "$(workers web1)" = 8 ] && [ "$(workers web2)" = 8 ]'
check "role knobs can be overridden from inventory (timeout)" overridable
check "site.yml converges" converged site.yml
verdict
