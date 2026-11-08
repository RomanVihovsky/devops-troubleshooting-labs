lint_cfg_untouched() {
  grep -qxE 'profile: *production' "$CI/.ansible-lint" && ! grep -qE '^\s*(skip_list|warn_list|exclude_paths|enable_list)\s*:' "$CI/.ansible-lint"
}
no_suppressions() {
  [ ! -s "$CI/.ansible-lint-ignore" ] && ! grep -rqs --include='*.yml' --include='*.yaml' 'noqa' "$CI" --exclude-dir=.git
}
check "ci/lint.sh passes" eval 'ctl_ci "sh ci/lint.sh" >> "$VERIFY_LOG" 2>&1'
check ".ansible-lint: profile production, nothing skipped" lint_cfg_untouched
check "no # noqa, no .ansible-lint-ignore" no_suppressions
check "site.yml converges" converged site.yml
check "web1 runs nginx with port=8080" eval 'svc_active web1 nginx && [ "$(nx web1 "cat /etc/acme/app.conf")" = "port=8080" ]'
verdict
