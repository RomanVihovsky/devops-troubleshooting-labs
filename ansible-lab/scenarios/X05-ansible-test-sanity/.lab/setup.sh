run_logged "$SETUP_LOG" ctl "ci/smoke.sh"
ws_commit "acme.ops 1.1.0: app_flag module (!412)" "Robin (shop team)"
echo "+ ci/sanity.sh   (the collection-sanity job)" >> "$SETUP_LOG"
if ctl "ci/sanity.sh" >> "$SETUP_LOG" 2>&1; then die "sanity passed in setup - fault not in place"; fi
