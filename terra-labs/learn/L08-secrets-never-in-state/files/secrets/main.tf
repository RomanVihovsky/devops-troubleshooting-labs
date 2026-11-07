# TODO 1: DB password - ephemeral random_password -> SSM /checkout/db/password (SecureString, value_wo)

# TODO 2: variable "partner_api_key" (ephemeral) -> Secrets Manager secret "checkout/partner-api-key"

resource "aws_ssm_parameter" "db_user" {
  name           = "/checkout/db/user"
  type           = "String"
  insecure_value = "checkout_app"
}
