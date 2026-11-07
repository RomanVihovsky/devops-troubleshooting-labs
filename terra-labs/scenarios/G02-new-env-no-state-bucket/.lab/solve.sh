run_logged "$SETUP_LOG" tg live/staging backend bootstrap --all
tg_apply_all live/staging
