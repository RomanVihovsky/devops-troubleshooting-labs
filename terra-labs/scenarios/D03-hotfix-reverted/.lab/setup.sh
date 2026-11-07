state_bucket
apply stacks/orders-db
sg=$(aws ec2 describe-security-groups --filters Name=group-name,Values=orders-db --query 'SecurityGroups[0].GroupId' --output text)
remember sg "$sg"
# INC-889, 03:12 - by hand
aws ssm put-parameter --name /orders/db/max-connections --type String --value 400 --overwrite >/dev/null
aws ec2 authorize-security-group-ingress --group-id "$sg" \
  --ip-permissions 'IpProtocol=tcp,FromPort=5432,ToPort=5432,IpRanges=[{CidrIp=10.30.0.0/16}]' >/dev/null
