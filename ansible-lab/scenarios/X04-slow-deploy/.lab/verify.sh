fast_noop() {
  docker exec -u ops "$CTL" bash -c 'for h in web1 web3 app1 app2; do ssh -O exit $h 2>/dev/null; done; rm -rf ~/.ansible/cp' >/dev/null 2>&1
  local t0=$SECONDS rc=0
  docker exec -u ops -w /ci -e ANSIBLE_NOCOLOR=1 "$CTL" timeout 60 ansible-playbook site.yml > "$CI/.lab-run.out" 2>&1 || rc=$?
  local t=$((SECONDS - t0)); echo "no-change run: rc=$rc ${t}s" >> "$VERIFY_LOG"; tail -6 "$CI/.lab-run.out" >> "$VERIFY_LOG"
  [ $rc -eq 0 ] && [ $t -lt 15 ] && grep -q 'changed=0' "$CI/.lab-run.out" && ! grep -qE 'changed=[1-9]' "$CI/.lab-run.out"
}
same_result() {
  local h; for h in web1 web3 app1 app2; do
    nx $h "command -v jq rsync unzip git socat >/dev/null && test -f /etc/acme-monitoring.conf" || return 1
  done
  [ "$(nx web1 "cat /etc/acme-role")" = "web on web1" ] && [ "$(nx app2 "cat /etc/acme-role")" = "app on app2" ]
}
check "a no-change run takes under 15 s" fast_noop
check "same result on the nodes" same_result
check "site.yml converges" converged site.yml
check "host key checking still on" not grep -qiE '^\s*host_key_checking\s*=\s*(false|no|0)' "$CI/ansible.cfg"
verdict
