no_tpl_warnings() {
  local out; out=$(ctl_ci "unset ANSIBLE_ALLOW_EMBEDDED_TEMPLATES; ansible-playbook site.yml --check 2>&1")
  echo "$out" | grep -iE 'embedded templates|templating delimiters' >> "$VERIFY_LOG" && return 1
  echo "$out" | grep -q 'failed=0'
}
check "deploy runs with the 2.23 preview" applies site.yml
check "prod web1 has the hardening marker" eval 'nx web1 "test -f /etc/acme/prod-hardening"'
check "staging web3 has no prod marker" eval 'nx web3 "! test -e /etc/acme/prod-hardening"'
check "only enabled sysctl settings are written" eval 'nx web1 "grep -q tcp_syncookies /etc/sysctl.d/90-acme.conf && ! grep -q unprivileged_bpf /etc/sysctl.d/90-acme.conf"'
check "no embedded-template / delimiter warnings (preview off)" no_tpl_warnings
check "site.yml converges" converged site.yml
check "ci/pipeline.sh still runs the 2.23 preview" eval 'grep -q "ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False" "$CI/ci/pipeline.sh"'
verdict
