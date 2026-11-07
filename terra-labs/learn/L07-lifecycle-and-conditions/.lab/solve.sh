python3 - <<'PY'
p = "shop/main.tf"
s = open(p).read()
s = s.replace("  # TODO 1: never destroy", "  lifecycle {\n    prevent_destroy = true\n  }")
s = s.replace('''  # TODO 3: replace when var.config_version changes
  # TODO 4: precondition - public_port in 18000-18999''', '''  lifecycle {
    replace_triggered_by = [terraform_data.config]

    precondition {
      condition     = var.public_port >= 18000 && var.public_port <= 18999
      error_message = "public_port must be in 18000-18999 (ops policy for this host)."
    }
  }''')
s = s.replace("  # TODO 2: stop reverting marketing's edits", "  lifecycle {\n    ignore_changes = [insecure_value]\n  }")
s = s.replace('''# TODO 5: check "web_up" - GET http://127.0.0.1:<public_port>/ must return 200''', '''resource "terraform_data" "config" {
  input = var.config_version
}

check "web_up" {
  data "http" "home" {
    url = "http://127.0.0.1:${var.public_port}/"
  }

  assert {
    condition     = data.http.home.status_code == 200
    error_message = "shop answered ${data.http.home.status_code}"
  }
}''')
open(p, "w").write(s)
PY
apply shop
sed -i 's/^config_version = 1/config_version = 2/' shop/terraform.tfvars
apply shop
