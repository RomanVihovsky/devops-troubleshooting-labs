output "db_user" {
  value = aws_ssm_parameter.db_user.insecure_value
}

# used by the migration job
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
