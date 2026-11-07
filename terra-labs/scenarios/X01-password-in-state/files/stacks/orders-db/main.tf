resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "db_user" {
  name           = "/orders/db/user"
  type           = "String"
  insecure_value = "orders_app"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/orders/db/password"
  description = "Master password of the orders database"
  type        = "SecureString"
  value       = random_password.db.result
}
