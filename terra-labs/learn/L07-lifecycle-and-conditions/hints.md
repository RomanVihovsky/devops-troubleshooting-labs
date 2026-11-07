## Hint 1
All three live in a resource's `lifecycle { ... }` block: `prevent_destroy = true`,
`ignore_changes = [insecure_value]`, `replace_triggered_by = [terraform_data.config]`.
`terraform_data` with `input = var.config_version` changes whenever the variable does.

## Hint 2
Preconditions also go into `lifecycle`:
`precondition { condition = var.public_port >= 18000 && var.public_port <= 18999  error_message = "..." }`.
Unlike variable validation, a precondition belongs to the resource and may use other resources' attributes.

## Hint 3
```
check "web_up" {
  data "http" "home" { url = "http://127.0.0.1:${var.public_port}/" }
  assert {
    condition     = data.http.home.status_code == 200
    error_message = "shop answered ${data.http.home.status_code}"
  }
}
```
A failing check is a **warning**, not an error - it reports, it does not block.
