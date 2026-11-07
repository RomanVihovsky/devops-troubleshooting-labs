# Solution - two roots, one state key

**Root cause**: `stacks/recs` was copied from `stacks/search` including the backend block, so both
roots read and write `search/terraform.tfstate`. To each pipeline the other team's resources are "in
state but not in my code" -> destroy. Every run flips the world.

**Diagnose**
```
diff stacks/search/versions.tf stacks/recs/versions.tf     # identical backend
terraform -chdir=stacks/recs plan                            # destroys /search/*, creates /recs/*
```

**Fix**: give recs its own key and start it **empty**:
```
sed -i 's|search/terraform.tfstate|recs/terraform.tfstate|' stacks/recs/versions.tf
terraform -chdir=stacks/recs init -reconfigure
terraform -chdir=stacks/recs apply
```
`-migrate-state` would have copied search's resources into recs' new state - and recs' next apply
would have destroyed search again.

**Interview notes**
* One state = one owner. Copy-pasted backends are the #1 cause; Terragrunt's
  `path_relative_to_include()` or a CI check for duplicate keys prevents it.
* Had recs already owned some resources, you would split the state: `terraform state mv` /
  `removed` + `import` blocks, per resource.
* "Plan shows destroys of things I never wrote" = read the backend first.
