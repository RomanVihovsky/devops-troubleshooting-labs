publish ansible-role-banner v1.1.0 "$SCN/.lab/role/v1" "banner role"
publish ansible-role-banner v1.2.0 "$SCN/.lab/role/v1" "release 1.2.0: Rocky 9 support"
run_logged "$SETUP_LOG" ctl "sh ci/pipeline.sh"
ws_commit "login banner from the platform role"
publish ansible-role-banner - "$SCN/.lab/role/v2" "WIP 2.0: banner_lines (list) replaces banner_text"
run_logged "$SETUP_LOG" ctl "sh ci/pipeline.sh" || true
