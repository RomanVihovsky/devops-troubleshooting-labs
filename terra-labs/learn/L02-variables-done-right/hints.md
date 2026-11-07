## Hint 1
`type = object({ name = string, port = optional(number, 8080), ... })`. Each rule is its own
`validation { condition = ..., error_message = "..." }` block; `can(regex(...))` turns a regex
miss into `false`, `contains([...], var.env)` checks a list.

## Hint 2
Cross-variable rule (Terraform >= 1.9): inside `variable "service"`'s validation you may use `var.env`:
`condition = var.env != "prod" || var.service.replicas >= 3`.
Sensitive input: `variable "api_token" { type = string  sensitive = true }` - no `default`.

## Hint 3
`resource "local_sensitive_file" "token" { filename = "${path.module}/out/${var.env}-${var.service.name}.token"
content = var.api_token }`. Precedence when the same variable is set twice:
`-var`/`-var-file` (last wins) > `*.auto.tfvars` > `terraform.tfvars(.json)` > `TF_VAR_*`.
