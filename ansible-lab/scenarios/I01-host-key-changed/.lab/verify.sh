real_fp() { nx web2 "ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub" | awk '{print $2}'; }
trusted_fp() { ssh-keygen -F web2 -f "$SSH_DIR/known_hosts" 2>/dev/null | grep -v '^#' | grep ed25519 | head -1 | awk '{print $2" "$3}' | ssh-keygen -lf - 2>/dev/null | awk '{print $2}'; }
no_hkc_off() {
  ! ws_has '^[[:space:]]*host_key_checking[[:space:]]*=[[:space:]]*(False|false|no|0)' &&
  ! ws_has 'StrictHostKeyChecking[= ]*no' && ! ws_has 'ANSIBLE_HOST_KEY_CHECKING'
}
check "site.yml runs cleanly and a second run changes nothing" idempotent site.yml
check "web2 serves the site" eval 'http_get http://web2:8080/ | grep -q "served by web2"'
check "the trusted key for web2 is web2's real host key" eval '[ -n "$(trusted_fp)" ] && [ "$(trusted_fp)" = "$(real_fp)" ]'
check "host key checking is not disabled anywhere" no_hkc_off
check "web1 was left alone (not rebuilt)" same_node web1
verdict
