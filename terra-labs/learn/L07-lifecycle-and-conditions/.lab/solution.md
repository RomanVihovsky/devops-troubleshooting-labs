# Solution - L07

Reference: `.lab/solve.sh`.

```hcl
resource "docker_volume" "data" {
  lifecycle { prevent_destroy = true }
}
resource "terraform_data" "config" { input = var.config_version }
resource "docker_container" "web" {
  lifecycle {
    replace_triggered_by = [terraform_data.config]
    precondition {
      condition     = var.public_port >= 18000 && var.public_port <= 18999
      error_message = "public_port must be in 18000-18999."
    }
  }
}
resource "aws_ssm_parameter" "banner" {
  lifecycle { ignore_changes = [insecure_value] }
}
check "web_up" {
  data "http" "home" { url = "http://127.0.0.1:${var.public_port}/" }
  assert { condition = data.http.home.status_code == 200  error_message = "..." }
}
```

**Takeaways**
* `prevent_destroy` blocks any plan that would destroy the resource - including replacements and
  removing the block from code *in the same change*. It does not stop `aws ... delete` or the console.
* `ignore_changes` hands an attribute's ownership to someone else. Use it narrowly; `ignore_changes = all`
  silently freezes a resource.
* `replace_triggered_by` (1.2+) needs a resource or `terraform_data` reference; `terraform_data`
  replaced `null_resource` for this.
* validation = inputs; precondition = assumption of a resource/data/output; postcondition = guarantee
  after apply; `check` = continuous assertion that only warns (1.5+).
* Gotcha for pipelines: a data source inside a `check` block is always re-read during apply, so
  `terraform plan -detailed-exitcode` returns **2** even when nothing changes. Drift detectors should
  look at the plan JSON (`resource_changes[].change.actions`) instead of trusting exit code 2 alone.
