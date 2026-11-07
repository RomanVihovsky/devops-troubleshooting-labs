## Hint 1
`git show --stat HEAD`. What file name does `find_in_parent_folders()` search for when you give it no argument?

## Hint 2
It defaults to `terragrunt.hcl` - which no longer exists above the units. Tell it which file to look for.

## Hint 3
`include "root" { path = find_in_parent_folders("root.hcl") }` in every unit (`grep -rl find_in_parent_folders live/`).
