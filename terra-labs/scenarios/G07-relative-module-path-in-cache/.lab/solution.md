# Solution - the // in terraform.source

**Root cause**: Terragrunt copies `terraform.source` into `.terragrunt-cache` and runs there. With
`../../../modules/app` only `app/` is copied; the module's `source = "../shared/names"` then points outside
the copy.

**Fix**: `source = "../../../modules//app"` - the part before `//` is copied as a whole, the part after
is the working directory.

**Interview notes**
* Same rule for remote sources: `git::https://...repo.git//modules/app?ref=v1.2.0`.
* Debug with `terragrunt run -- init` and look into `.terragrunt-cache`; `--source-update` refreshes it.
* `--source` / `TG_SOURCE` + `//` let you test a local checkout of a module repo against a live unit.
