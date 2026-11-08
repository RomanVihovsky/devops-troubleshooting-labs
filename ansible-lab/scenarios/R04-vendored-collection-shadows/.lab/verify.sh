resolved_version() {   # from a playbook next to site.yml: playbook-adjacent collections/ count
  printf -- '- hosts: localhost
  gather_facts: false
  tasks:
    - ansible.builtin.debug:
        msg: "cg={{ lookup(%s, %s) }}"
' \
    "'community.general.collection_version'" "'community.general'" > "$CI/.lab-cv.yml"
  ctl_ci "ansible-playbook .lab-cv.yml" 2>&1 | tee -a "$VERIFY_LOG" | grep -q '"msg": "cg=14.0.0"'
}
check "site.yml deploys" applies site.yml
check "logrotate policy for /var/log/acme (daily, 14)" eval 'nx web1 "grep -q /var/log/acme /etc/logrotate.d/acme && grep -q daily /etc/logrotate.d/acme && grep -qE \"rotate +14\" /etc/logrotate.d/acme"'
check "the repo resolves community.general 14.0.0" resolved_version
check "site.yml converges" converged site.yml
verdict
