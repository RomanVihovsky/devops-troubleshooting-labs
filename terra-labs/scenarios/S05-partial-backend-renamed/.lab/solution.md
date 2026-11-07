# Solution - partial backend config file renamed, CI script not updated

**Root cause**: the cleanup renamed `backend/prod.hcl` to `backend/prod.s3.tfbackend`. `ci/plan.sh`
only passes `-backend-config` *if* `backend/$env.hcl` exists - so now it silently runs `init` with an
empty `backend "s3" {}` and Terraform rightly complains about the missing bucket. The author's laptop
still had the old settings cached in `.terraform/terraform.tfstate`.

**Fix**: use the new file and fail loudly when it is missing:
```bash
cfg="backend/$env.s3.tfbackend"
[ -f "$cfg" ] || { echo "no backend config $cfg" >&2; exit 2; }
terraform init -input=false -backend-config="$cfg"
```

**Interview notes**
* Partial backend configuration keeps env-specific settings out of code; the `.tfbackend` extension is
  the documented convention (HCL syntax). `-backend-config` also takes `key=value` pairs.
* "Optional" config in CI scripts turns errors into silent misbehaviour - fail fast.
* Always reproduce CI failures from a clean checkout (`.terraform/` caches backend config and providers).
