# Solution - L10

Reference: `.lab/solve.sh`. Layout:
```
live/
  root.hcl                 remote_state + generate provider + common inputs
  dev/env.hcl              locals { env = "dev" }
  dev/web/terragrunt.hcl   include root, terraform.source, inputs
modules/web-config/        plain Terraform, no provider/backend
```

**Takeaways**
* One `root.hcl` defines backend and provider once; each unit is a few lines. Since Terragrunt 0.80/1.0
  the root is **`root.hcl`** - a root `terragrunt.hcl` makes `run --all` treat it as a unit
  (incident G03 is the migration).
* `path_relative_to_include()` gives every unit its own state key automatically.
* 1.x never creates backend resources implicitly: `terragrunt backend bootstrap` (or
  `--backend-bootstrap`) creates the bucket with versioning, encryption, public access block and
  a TLS-only policy (incident G02).
* `//` in `source` = "copy the whole repo/dir, then cd into this subdir" - modules can then use
  relative paths to siblings (incident G07).
* Debug the final config with `terragrunt render --json` and `--inputs-debug`.
