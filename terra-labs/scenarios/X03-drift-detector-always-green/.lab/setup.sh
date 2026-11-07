state_bucket
apply stacks/payments
aws ssm put-parameter --name /payments/max-transaction-eur --type String --value 50000 --overwrite >/dev/null
