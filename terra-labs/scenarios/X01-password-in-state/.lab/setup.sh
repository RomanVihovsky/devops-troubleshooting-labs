# X01 - a generated password stored via random_password + value + an output: all in state.
aws s3api create-bucket --bucket acme-tfstate \
  --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled
apply stacks/orders-db
remember leaked "$(ssm_value /orders/db/password)"
