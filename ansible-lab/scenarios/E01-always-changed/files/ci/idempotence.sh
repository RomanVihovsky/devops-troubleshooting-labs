#!/bin/sh
# CI gate: the second run must change nothing
set -eu
ansible-playbook site.yml
ansible-playbook site.yml | tee .idem.log
grep -qE 'changed=0 +unreachable=0 +failed=0' .idem.log || { echo "IDEMPOTENCE CHECK FAILED"; exit 1; }
