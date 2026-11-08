sed -i 's/ansible-core==2.22.0/ansible-core==2.17.14/' requirements-ci.txt
# the past: ansible-core < 2.19 accepted truthy strings/ints in conditionals (simulated with the escape hatch)
run_logged "$SETUP_LOG" ctl "ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True ansible-playbook site.yml"
ws_commit "web role with TLS policy and MOTD"
sed -i 's/ansible-core==2.17.14/ansible-core==2.22.0/' requirements-ci.txt
ws_commit "ci: bump ansible-core to 2.22.0" "renovate[bot]"
