db=$(recall db_sg)
app_sg=$(aws ec2 describe-security-groups --filters Name=group-name,Values=prod-app --query 'SecurityGroups[0].GroupId' --output text)
rule() {
  [ "$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$db" \
     --query "length(SecurityGroupRules[?!IsEgress && FromPort==\`5432\` && ReferencedGroupInfo.GroupId=='$app_sg'])" --output text)" = 1 ]
}
no_cycle() { (cd "$CI/live/prod" && terragrunt dag graph --log-level error) >> "$VERIFY_LOG" 2>&1; }
check "db SG allows 5432 from the app SG" rule
check "the DAG has no cycle (dag graph works)" no_cycle
check "db security group is the original" test "$(aws ec2 describe-security-groups --filters Name=group-name,Values=prod-db --query 'SecurityGroups[0].GroupId' --output text)" = "$db"
check "terragrunt run --all plan in live/prod: no changes" tg_plan_clean live/prod
verdict
