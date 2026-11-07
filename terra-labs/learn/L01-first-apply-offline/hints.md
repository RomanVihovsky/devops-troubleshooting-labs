## Hint 1
`required_providers` takes a map: `random = { source = "hashicorp/random", version = "~> 3.7" }`.
`terraform providers` shows what the configuration needs. Look up resource arguments with
`terraform providers schema -json | jq` or the registry docs you know.

## Hint 2
`random_pet` has `length` and `separator`; its result is `.id`. `local_file` needs `filename`
(use `"${path.module}/out/greeting.txt"`) and `content` (`"Hello, ${random_pet.name.id}!"`).

## Hint 3
Order matters: `init` -> `plan -out=tfplan` -> `apply tfplan` -> `plan -detailed-exitcode` (0).
Then commit the lock file - `git status` should not list `hello/.terraform.lock.hcl` any more.
