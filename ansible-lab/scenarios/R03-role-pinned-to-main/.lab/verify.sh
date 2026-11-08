pinned_tag() {
  local v; v=$(python3 -c 'import sys,yaml; r=yaml.safe_load(open(sys.argv[1])) or {}; print(next((str(x.get("version","")) for x in r.get("roles",[]) if "ansible-role-banner" in str(x.get("src",""))), ""))' "$CI/requirements.yml") || return 1
  echo "pinned: $v" >> "$VERIFY_LOG"
  [ -n "$v" ] && ctl_ci "git ls-remote --tags https://git.acme.example/platform/ansible-role-banner.git" | grep -q "refs/tags/$v\$"
}
fresh_install() { ctl_ci "ansible-galaxy role install -r requirements.yml --force" >> "$VERIFY_LOG" 2>&1; }
banner_ok() { nx "$1" "grep -qx 'ACME Corp - authorized access only. Activity is logged.' /etc/issue.net"; }
check "acme.banner is pinned to a released tag" pinned_tag
check "fresh role install works" fresh_install
check "site.yml converges with the pinned role" converged site.yml
check "banners unchanged on web1 and web2" eval 'banner_ok web1 && banner_ok web2'
verdict
