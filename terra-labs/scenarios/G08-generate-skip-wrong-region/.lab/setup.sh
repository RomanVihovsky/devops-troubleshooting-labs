run_logged "$SETUP_LOG" tg live/prod/notifier backend bootstrap
tg_apply_all live/prod
