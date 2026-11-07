state_bucket
python3 - <<'PY'
p = "stacks/edge/main.tf"
s = open(p).read()
s = s.replace('''
  # security review: the LB may only talk to the app tier
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
''', "")
open(p, "w").write(s)
PY
apply stacks/edge
for g in lb app; do remember "sg_$g" "$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$g" --query 'SecurityGroups[0].GroupId' --output text)"; done
ws_commit "edge: lb + app security groups"
cp "$SCN/files/stacks/edge/main.tf" stacks/edge/main.tf
ws_commit "security: lb egress only to the app tier" "Security team"
