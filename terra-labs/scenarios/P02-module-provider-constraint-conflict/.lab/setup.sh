for v in v1.3.0 v1.4.0 v2.0.0; do publish tf-module-topic "$v" "$SCN/.lab/modules/$v" "release $v"; done
state_bucket
sed -i 's/?ref=v1.4.0/?ref=v1.3.0/' stacks/events/main.tf
apply stacks/events
for t in orders refunds; do
  arn=$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':$t-events')].TopicArn | [0]" --output text)
  aws sns subscribe --topic-arn "$arn" --protocol email --notification-endpoint "$t-oncall@acme.example" >/dev/null
done
ws_commit "events: orders + refunds topics (tf-module-topic v1.3.0)"
sed -i 's/?ref=v1.3.0/?ref=v1.4.0/' stacks/events/main.tf
ws_commit "chore(deps): update tf-module-topic to v1.4.0" "renovate[bot]"
