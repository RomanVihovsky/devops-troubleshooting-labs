resource "aws_vpc" "main" {
  cidr_block = "10.70.0.0/16"
  tags       = { Name = "edge" }
}

resource "aws_security_group" "lb" {
  name        = "lb"
  description = "load balancer"
  vpc_id      = aws_vpc.main.id

  # security review: the LB may only talk to the app tier
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group" "app" {
  name        = "app"
  description = "app tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }
}
