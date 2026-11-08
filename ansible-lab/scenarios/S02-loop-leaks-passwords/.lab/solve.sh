sed -i 's/^      loop: "{{ onboarding_users }}"$/      loop: "{{ onboarding_users }}"\n      loop_control:\n        label: "{{ item.name }}"\n      no_log: true/' site.yml
grep -q 'no_log: true' site.yml
run_logged "$SETUP_LOG" ctl "sh ci/deploy.sh"
