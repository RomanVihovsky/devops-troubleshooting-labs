resource "aws_vpc" "main" {
  cidr_block = "10.50.0.0/16"
  tags       = { Name = "db" }
}

resource "aws_security_group" "db" {
  name        = "db"
  description = "postgres"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "app"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.50.1.0/24"]
  }
}
