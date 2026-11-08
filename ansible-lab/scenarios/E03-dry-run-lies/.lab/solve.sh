sed -i 's/^      register: app_current$/      register: app_current\n      check_mode: false/' site.yml
grep -q 'check_mode: false' site.yml
run_logged "$SETUP_LOG" ctl "sh ci/pr-check.sh"
