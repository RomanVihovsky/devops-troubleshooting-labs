## Hint 1
The error names the module and its constraint. What does `~> 1.9.0` allow? (`~>` lets only the
right-most given component grow.)

## Hint 2
`~> 1.9.0` = ">= 1.9.0, < 1.10.0". `~> 1.9` = ">= 1.9, < 2.0". Modules usually state a minimum.

## Hint 3
`required_version = ">= 1.9, < 2.0"` (or `~> 1.9`). Keep the constraint - it documents what the
module needs. Then `terraform init` and plan.
