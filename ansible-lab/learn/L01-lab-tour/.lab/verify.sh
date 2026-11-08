inv_ok() {
  local g; g=$(ctl_ci "ansible-inventory --list" 2>>"$VERIFY_LOG") || return 1
  jq -e '(.web.hosts | sort) == ["web1","web2"]' <<<"$g" >/dev/null &&
    [ "$(ctl_ci "ansible-inventory --host web2" | jq -r .tier)" = frontend ]
}
cfg_ok() {
  local d; d=$(ctl_ci "ansible-config dump --only-changed -t base" 2>>"$VERIFY_LOG")
  grep -qE '^DEFAULT_FORKS.*= 20' <<<"$d" && grep -qE '^DEFAULT_REMOTE_USER.*= ansible' <<<"$d" &&
    grep -qE '^DEFAULT_HOST_LIST.*hosts.yml' <<<"$d"
}
ping_ok() { ctl_ci "ansible all -m ansible.builtin.ping" >> "$VERIFY_LOG" 2>&1; }
check "inventory: group web = web1 + web2, tier: frontend" inv_ok
check "ansible.cfg: inventory, remote_user ansible, forks 20" cfg_ok
check "ansible all -m ping works without -i" ping_ok
check "user deploy exists on web1 and web2 (bash)" eval 'nx web1 "getent passwd deploy | grep -q /bin/bash" && nx web2 "getent passwd deploy | grep -q /bin/bash"'
verdict
