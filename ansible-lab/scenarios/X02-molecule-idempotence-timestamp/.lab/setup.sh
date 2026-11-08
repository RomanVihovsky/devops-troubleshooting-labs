ws_commit "node_report role + molecule"
run_logged "$SETUP_LOG" ctl "sh ci/molecule.sh" || true
