## Hint 1
Terragrunt does not run Terraform in `modules/app` - it **copies** the source into
`.terragrunt-cache/<hash>/...` first. Look inside it: is `shared/` there?

## Hint 2
Only the directory named in `source` is copied. A relative path inside the module that climbs out of it
(`../shared`) points to nothing in the cache.

## Hint 3
The double slash: `source = "../../../modules//app"` copies everything under `modules/` and then runs in
`app/` - so `../shared/names` resolves. Same syntax as `git::...//modules/app?ref=...`.
