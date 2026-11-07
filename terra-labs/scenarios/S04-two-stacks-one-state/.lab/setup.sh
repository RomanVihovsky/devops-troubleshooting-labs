state_bucket
apply stacks/search
apply stacks/recs      # destroys search's resources, creates recs'
apply stacks/search    # and back again
remember search_topic "$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':search-index-updates')].TopicArn | [0]" --output text)"
remember search_param "$(aws ssm get-parameter --name /search/index --query Parameter.LastModifiedDate --output text)"
