ap site.yml
ws_commit "app play"
run_logged "$SETUP_LOG" ctl "sh ci/pr-check.sh" || true
