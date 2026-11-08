pw=$(recall dbpw)
leaks() { grep -qF -- "$1" "$CI/.lab-run.log"; }   # in the verbose CI run (-v --diff, human output)
verbose_run() {
  local args=()
  mapfile -t args < <(ctl_env_args)
  docker exec -u ops -w /ci "${args[@]}" -e ANSIBLE_NOCOLOR=1 "$CTL" ansible-playbook site.yml -v --diff > "$CI/.lab-run.log" 2>&1
  local rc=$?
  cat "$CI/.lab-run.log" >> "$VERIFY_LOG"
  return $rc
}
no_leak() {
  local n t b
  ! leaks "$pw" || return 1
  for n in web1 web2; do
    t=$(recall "tok.$n"); b=$(printf '%s\n' "$t" | base64)
    ! leaks "$t" || return 1
    ! leaks "$b" || return 1
  done
}
env_ok() { nx "$1" "cat /etc/acme/app.env" | grep -qx "DB_PASSWORD=$pw" && nx "$1" "cat /etc/acme/app.env" | grep -qx "API_TOKEN=$(recall "tok.$1")"; }
check "group_vars/web/vault.yml is encrypted with vault ID prod" eval 'head -1 "$CI/group_vars/web/vault.yml" | grep -q "^\$ANSIBLE_VAULT;1.2;AES256;prod"'
check "no plain DB password anywhere in the repo" not grep -rqF --exclude-dir=.git -- "$pw" "$CI"
check "a verbose CI run (-v --diff) works" verbose_run
check "...and prints neither the password nor the token (plain or base64)" no_leak
check "env files on both nodes hold the right values" eval 'env_ok web1 && env_ok web2'
check "site.yml converges" converged site.yml
verdict
