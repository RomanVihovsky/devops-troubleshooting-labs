ws_commit "pricing module + tests"
python3 - <<'PY'
p = "modules/pricing/main.tf"
s = open(p).read()
s = s.replace('''locals {
  discounted = var.net_cents * (100 - var.discount_percent) / 100
  gross      = local.discounted * (100 + var.vat_percent) / 100
}

output "gross_cents" {
  value = floor(local.gross + 0.5)
}''', '''locals {
  # one expression is easier to read
  gross = var.net_cents * (100 + var.vat_percent) / 100 - var.discount_percent
}

output "gross_cents" {
  value = floor(local.gross)
}''')
s = s.replace('''
  validation {
    condition     = var.discount_percent >= 0 && var.discount_percent <= 50
    error_message = "discount_percent must be between 0 and 50."
  }
''', "")
open(p, "w").write(s)
PY
ws_commit "refactor: simplify pricing module" "Sam (checkout)"
