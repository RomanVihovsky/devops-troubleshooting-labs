# G04 - prod was stood up unit by unit: `app` was applied before `storage`, and the dependency's
# unrestricted mock_outputs went straight into prod.
run_logged "$SETUP_LOG" tg live/prod/storage backend bootstrap
run_logged "$SETUP_LOG" tg live/prod/app apply -auto-approve -input=false -no-color
run_logged "$SETUP_LOG" tg live/prod/storage apply -auto-approve -input=false -no-color
echo 'avatar-42.png' | aws s3 cp - s3://acme-prod-uploads/avatars/42.png >/dev/null
