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
s += '''
# security review: the LB may only talk to the app tier.
# A separate rule resource depends on both groups -> no cycle.
resource "aws_vpc_security_group_egress_rule" "lb_to_app" {
  security_group_id            = aws_security_group.lb.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
'''
open(p, "w").write(s)
PY
apply stacks/edge
