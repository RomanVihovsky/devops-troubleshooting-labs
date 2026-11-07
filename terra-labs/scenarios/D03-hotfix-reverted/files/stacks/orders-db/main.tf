resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  tags       = { Name = "orders" }
}

resource "aws_security_group" "db" {
  name        = "orders-db"
  description = "orders database"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "10.10.0.0/16"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "orders app"
}

resource "aws_ssm_parameter" "max_connections" {
  name           = "/orders/db/max-connections"
  type           = "String"
  insecure_value = "100"
}
