cold_fast() {
  docker exec -u ops "$CTL" bash -c 'ssh -O exit web1 2>/dev/null; ssh -O exit web2 2>/dev/null; rm -rf ~/.ansible/cp /tmp/ansible-facts' >/dev/null 2>&1
  local t0=$SECONDS rc=0
  docker exec -u ops -w /ci -e ANSIBLE_NOCOLOR=1 "$CTL" timeout 30 ansible-playbook site.yml >> "$VERIFY_LOG" 2>&1 || rc=$?
  echo "cold run: rc=$rc $((SECONDS - t0))s" >> "$VERIFY_LOG"
  [ $rc -eq 0 ] && [ $((SECONDS - t0)) -lt 12 ]
}
cfg() { ctl_ci "ansible-config dump --only-changed -t all" 2>/dev/null; }
callbacks_on() { cfg | grep -E '^CALLBACKS_ENABLED' | grep -q profile_tasks; }
mux_ok() {
  cfg | grep -qiE 'pipelining.*= True' &&
    ! grep -rqsE 'ControlMaster[= ]*no' "$CI/ansible.cfg"
}
check "a cold run of site.yml takes under 12 s" cold_fast
check "UseDNS is off on both nodes" eval 'nx web1 "sshd -T | grep -qx \"usedns no\"" && nx web2 "sshd -T | grep -qx \"usedns no\""'
check "profile_tasks/timer callbacks enabled" callbacks_on
check "pipelining on, SSH multiplexing not disabled" mux_ok
check "host key checking still on" not grep -qiE '^\s*host_key_checking\s*=\s*(false|no|0)' "$CI/ansible.cfg"
check "site.yml converges" converged site.yml
verdict
