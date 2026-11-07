# After "rename root terragrunt.hcl to root.hcl", nothing plans any more
**INFRA-293** · P2 · Reporter: platform

Following the Terragrunt 1.x migration guide, someone renamed `live/terragrunt.hcl` to `live/root.hcl`.
Since then every unit fails while parsing its config (`find_in_parent_folders` can't find what it looks
for). Rolling back the rename is not wanted - a root `terragrunt.hcl` is treated as a unit by `run --all`.

**Test**: `terragrunt run --all plan` in `live/` shows no changes; there is no `live/terragrunt.hcl`.
