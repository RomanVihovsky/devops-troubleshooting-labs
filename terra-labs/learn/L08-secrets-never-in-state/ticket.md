# L08 · Secrets that never touch state
**Learn** · ephemeral resources & variables, write-only arguments · ~25 min

`secrets/` must create two secrets for the checkout service - and the state must never contain them.
`sensitive = true` is not enough: it only hides values in the CLI; the state is plain JSON.

1. **DB password**: generate it with an `ephemeral "random_password"` (24 chars) and store it in SSM
   `/checkout/db/password` (SecureString) through the **write-only** argument `value_wo`
   (plus `value_wo_version`).
2. **Partner API key**: the vendor gave us a key - it is in your shell as `TF_VAR_partner_api_key`.
   Declare `variable "partner_api_key"` as **ephemeral** (and sensitive) and store it in Secrets Manager:
   secret `checkout/partner-api-key`, version via `secret_string_wo` + `secret_string_wo_version`.
3. `terraform apply`. Check the state: `terraform state pull | grep -c <the key>` -> 0.
4. Try to leak it on purpose: add `output "oops" { value = var.partner_api_key }` and plan. Read the
   error, then remove the output again.

**Test**: both secrets exist with the right values and types; neither appears in the state; the
variable is ephemeral (a root output of it is rejected); a CI plan shows no changes.
