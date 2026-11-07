d=stacks/notifications
originals() {
  [ "$(aws iam get-role --role-name notifier --query Role.RoleId --output text 2>/dev/null)" = "$(recall role_id)" ] &&
  [ "$(aws sns list-topics --query "length(Topics[?ends_with(TopicArn, ':refunds-events')])" --output text)" = 1 ] &&
  [ "$(aws ssm get-parameter --name /notifications/refunds-topic-arn --query Parameter.Version --output text)" = 1 ]
}
check "CI plan of stacks/notifications shows no changes" plan_clean $d
check "state knows the refunds topic, role and parameter" eval 'in_state $d aws_sns_topic.refunds && in_state $d aws_iam_role.notifier && in_state $d aws_ssm_parameter.refunds_topic'
check "they are the originals (same role, one topic, parameter untouched)" originals
verdict
