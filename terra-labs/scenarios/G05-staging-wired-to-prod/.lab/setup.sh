run_logged "$SETUP_LOG" tg live/prod/network backend bootstrap
tg_apply_all live/prod
tg_apply_all live/staging
remember prod_sg "$(aws ec2 describe-security-groups --filters Name=group-name,Values=prod-app --query 'SecurityGroups[0].GroupId' --output text)"
