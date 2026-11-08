r=roles/node_report
mol() { ctl_ci "cd $1 && ANSIBLE_ROLES_PATH=/ci/${2:-roles} molecule test" >> "$VERIFY_LOG" 2>&1; }
mutant() {   # mutant <sed expr> <file>: copy the role, change it, molecule must FAIL
  local m="mutants-$RANDOM"
  mkdir -p "$CI/$m" && cp -r "$CI/$r" "$CI/$m/" && sed -i "$1" "$CI/$m/node_report/$2"
  echo "+ mutant $1 ($2)" >> "$VERIFY_LOG"
  ! mol "/ci/$m/node_report" "$m"
}
real_change_reported() {   # tamper with the report on test1: the role must put it back and say "changed"
  nx test1 "sed -i 's/^kernel=.*/kernel=tampered/' /etc/acme/node-report.txt" &&
    printf -- '- name: Report\n  hosts: test\n  become: true\n  roles:\n    - node_report\n' > "$CI/.lab-report.yml" &&
    applies .lab-report.yml && stats_ok '.changed >= 1' && ! nx test1 "grep -q tampered /etc/acme/node-report.txt"
}
check "ci/molecule.sh passes" eval 'ctl_ci "sh ci/molecule.sh" >> "$VERIFY_LOG" 2>&1'
check "a tampered report is repaired and reported as changed" real_change_reported
check "no changed_when / check_mode on the report task" not grep -qE '^\s*(changed_when|check_mode):' "$CI/$r/tasks/main.yml"
check "mutant: a task that always changes -> molecule fails" mutant '$a- name: Touch a stamp\n  ansible.builtin.command: touch /tmp/stamp' tasks/main.yml
verdict
