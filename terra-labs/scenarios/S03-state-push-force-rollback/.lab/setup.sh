state_bucket
mv stacks/notifications/refunds.tf "$STATE_DIR/refunds.tf"
apply stacks/notifications
tf stacks/notifications state pull > "$STATE_DIR/laptop-copy.tfstate"
ws_commit "notifications: orders topic"
mv "$STATE_DIR/refunds.tf" stacks/notifications/refunds.tf
apply stacks/notifications
ws_commit "notifications: refunds topic + notifier role" "Sam (notifications)"
remember role_id "$(aws iam get-role --role-name notifier --query Role.RoleId --output text)"
remember refunds_arn "$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':refunds-events')].TopicArn | [0]" --output text)"
# the "fix": an old laptop copy pushed over the real state
run_logged "$SETUP_LOG" tf stacks/notifications state push -force "$STATE_DIR/laptop-copy.tfstate"
rm -f "$STATE_DIR/laptop-copy.tfstate"
