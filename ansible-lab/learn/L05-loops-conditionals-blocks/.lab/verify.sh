admin_group() { if [ "$(node_os "$1")" = rocky ]; then echo wheel; else echo sudo; fi; }
users_ok() {
  local n g
  for n in web1 web2; do
    g=$(admin_group $n)
    nx $n "id -nG alice" | grep -qw "$g" || return 1
    nx $n "id bob" >/dev/null || return 1
    ! nx $n "id -nG bob" | grep -qw "$g" || return 1
    ! nx $n "id carol" >/dev/null 2>&1 || return 1
  done
}
check "alice (admin per OS) and bob exist, carol is gone" users_ok
check "/etc/acme/agent-missing on both nodes (rescue ran)" eval 'nx web1 "test -f /etc/acme/agent-missing" && nx web2 "test -f /etc/acme/agent-missing"'
check "users.yml converges (check mode: no changes)" converged users.yml
verdict
