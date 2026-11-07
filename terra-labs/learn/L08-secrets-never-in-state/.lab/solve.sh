cat > secrets/main.tf <<'TF'
ephemeral "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name             = "/checkout/db/password"
  type             = "SecureString"
  value_wo         = ephemeral.random_password.db.result
  value_wo_version = 1
}

variable "partner_api_key" {
  type        = string
  description = "Key issued by the payment partner. Pass via TF_VAR_partner_api_key."
  ephemeral   = true
  sensitive   = true
}

resource "aws_secretsmanager_secret" "partner" {
  name = "checkout/partner-api-key"
}

resource "aws_secretsmanager_secret_version" "partner" {
  secret_id                = aws_secretsmanager_secret.partner.id
  secret_string_wo         = var.partner_api_key
  secret_string_wo_version = 1
}

resource "aws_ssm_parameter" "db_user" {
  name           = "/checkout/db/user"
  type           = "String"
  insecure_value = "checkout_app"
}
TF
apply secrets
