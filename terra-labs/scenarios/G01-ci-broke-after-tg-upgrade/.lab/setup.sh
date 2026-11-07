run_logged "$SETUP_LOG" tg live/prod/network backend bootstrap
tg_apply_all live/prod
