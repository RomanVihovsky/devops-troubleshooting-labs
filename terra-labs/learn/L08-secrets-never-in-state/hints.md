## Hint 1
Ephemeral values may only flow into ephemeral places: write-only arguments (`*_wo`), provider
configuration, other ephemeral resources/variables/locals. `value_wo` needs `value_wo_version`: the
provider only sends the value when the version changes (bump it to rotate).

## Hint 2
```
variable "partner_api_key" {
  type      = string
  ephemeral = true
  sensitive = true
}
```
`aws_secretsmanager_secret` holds the metadata; `aws_secretsmanager_secret_version` the value
(`secret_string_wo`, `secret_string_wo_version`).

## Hint 3
`terraform state pull | jq '.resources[].instances[].attributes | {value, value_wo, secret_string, secret_string_wo}'`
-> all `null` (write-only arguments are never stored). The "oops" output fails with
"Ephemeral value not allowed" - which is exactly the protection you want.
