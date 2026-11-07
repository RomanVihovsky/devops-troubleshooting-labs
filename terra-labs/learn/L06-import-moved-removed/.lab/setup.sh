aws s3api create-bucket --bucket acme-tfstate --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled
apply stacks/legacy
echo 'month,revenue' | aws s3 cp - s3://acme-legacy-reports/2026/10.csv >/dev/null
# made by hand, long ago
for f in checkout:on search:off recs:on; do
  aws ssm put-parameter --name "/legacy/flags/${f%%:*}" --type String --value "${f#*:}" >/dev/null
done
aws iam create-role --role-name legacy-reporting --description "Nightly reporting job" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
remember role_id "$(aws iam get-role --role-name legacy-reporting --query Role.RoleId --output text)"
