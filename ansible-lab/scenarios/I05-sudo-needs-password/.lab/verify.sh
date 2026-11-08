pw=$(recall becomepw)
vaulted() {
  local f
  for f in $(grep -rlE '^\$ANSIBLE_VAULT;1\.2;AES256;prod' "$CI/group_vars" "$CI/host_vars" 2>/dev/null); do
    ctl_ci "ansible-vault view $(realpath --relative-to="$CI" "$f")" 2>/dev/null | grep -qF -- "$pw" && return 0
  done
  return 1
}
still_password() { for n in web1 web2; do ! nx $n "grep -rqsE '^[^#]*NOPASSWD' /etc/sudoers /etc/sudoers.d" || return 1; done; }
check "site.yml converges non-interactively" converged site.yml
check "the become password is in a vault file with ID prod" vaulted
check "no plaintext password in the repo" not grep -rqF --exclude-dir=.git -- "$pw" "$CI"
check "sudo on the nodes still requires a password (no NOPASSWD)" still_password
verdict
