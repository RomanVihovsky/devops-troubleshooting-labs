# Solution - tell find_in_parent_folders which file to find

**Root cause**: `find_in_parent_folders()` without an argument looks for `terragrunt.hcl`. After the rename
there is none above the units, so including the root fails.

**Fix**: `find_in_parent_folders("root.hcl")` in every unit.

**Interview notes**
* Why rename at all: with a root `terragrunt.hcl`, `run --all` from `live/` treats the root as a unit
  itself; Terragrunt 1.x warns/strict-controls this (`terragrunt info strict`).
* `find_in_parent_folders("env.hcl")` + `read_terragrunt_config()` is the standard way to layer
  env/region/account config.
