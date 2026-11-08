r=roles/sshd_hardening
lint_clean() { ctl_ci "ansible-lint --offline --profile production --nocolor $r" >> "$VERIFY_LOG" 2>&1 && [ ! -s "$CI/.ansible-lint-ignore" ]; }
no_skips() { ! grep -rqsE '^\s*(skip_list|warn_list)' "$CI"/.ansible-lint* "$CI/$r"/.ansible-lint* 2>/dev/null; }
mol() { ctl_ci "cd $1 && ANSIBLE_ROLES_PATH=/ci/${2:-roles} molecule test" >> "$VERIFY_LOG" 2>&1; }
mutant() {   # mutant <sed expr> <file>: copy the role, break it, molecule must FAIL
  local m="mutants-$RANDOM"
  mkdir -p "$CI/$m" && cp -r "$CI/roles/sshd_hardening" "$CI/$m/" && sed -i "$1" "$CI/$m/sshd_hardening/$2"
  echo "+ mutant $1 ($2)" >> "$VERIFY_LOG"
  ! mol "/ci/$m/sshd_hardening" "$m"
}
check "ansible-lint (production profile) reports nothing" lint_clean
check "no skip/warn lists to hide findings" no_skips
check "molecule test passes on a fresh checkout" mol /ci/$r
check "mutant: a task that always changes -> molecule fails (idempotence)" mutant '$a- name: Touch a stamp\n  ansible.builtin.command: touch /tmp/stamp' tasks/main.yml
check "mutant: PermitRootLogin line removed -> molecule fails (verify)" mutant '/PermitRootLogin/d' templates/hardening.conf.j2
verdict
