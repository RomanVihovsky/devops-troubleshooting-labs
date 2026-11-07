# Solution - L02

See the reference in `.lab/solve.sh`. Key pieces:
```hcl
variable "service" {
  type = object({
    name     = string
    port     = optional(number, 8080)
    replicas = optional(number, 2)
    tags     = optional(map(string), {})
  })
  validation {
    condition     = var.env != "prod" || var.service.replicas >= 3     # cross-variable, TF >= 1.9
    error_message = "prod needs at least 3 replicas."
  }
}
variable "api_token" { type = string  sensitive = true }
```

**Takeaways**
* Types are documentation that the CLI enforces. `optional(type, default)` (TF 1.3+) gives object
  inputs real defaults - callers only set what differs.
* Validation runs at plan time; since 1.9 it may reference other variables, data sources and locals.
* `sensitive = true` redacts values in plan/output - it does **not** keep them out of state
  (`local_sensitive_file.content` is in state). For that you need ephemeral values: L08.
* Precedence: `-var`/`-var-file` (in order) > `*.auto.tfvars` (alphabetical) > `terraform.tfvars.json`
  > `terraform.tfvars` > `TF_VAR_*`. A stray `*.auto.tfvars` is incident C03.
