cat > stacks/orders-db/main.tf <<'TF'
# Generated per run, never stored in plan or state (Terraform >= 1.10).
ephemeral "random_password" "db" {
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

  # write-only: sent to AWS only when value_wo_version changes, never stored in state
  value_wo         = ephemeral.random_password.db.result
  value_wo_version = 2 # bump to rotate
}
TF
cat > stacks/orders-db/outputs.tf <<'TF'
output "db_user" {
  value = aws_ssm_parameter.db_user.insecure_value
}

# The migration job reads the password from SSM /orders/db/password at runtime.
TF
apply stacks/orders-db
