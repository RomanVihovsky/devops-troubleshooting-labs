state_bucket
mv stacks/db/reporting.tf "$STATE_DIR/reporting.tf"
apply stacks/db
ws_commit "db: postgres security group"
mv "$STATE_DIR/reporting.tf" stacks/db/reporting.tf
ws_commit "db: allow reporting jobs" "Data team"
apply stacks/db    # adds the rule
apply stacks/db    # ... and the group removes it again
remember sg "$(aws ec2 describe-security-groups --filters Name=group-name,Values=db --query 'SecurityGroups[0].GroupId' --output text)"
