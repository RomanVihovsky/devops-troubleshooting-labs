# Added by the data team for the reporting jobs.
resource "aws_security_group_rule" "reporting" {
  type              = "ingress"
  description       = "reporting"
  security_group_id = aws_security_group.db.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["10.60.0.0/16"]
}
