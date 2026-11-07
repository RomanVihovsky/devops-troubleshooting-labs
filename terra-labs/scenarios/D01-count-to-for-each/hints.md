## Hint 1
Compare the addresses: `terraform state list` (old: `docker_container.web[0]` ...) and what the plan
wants to create (`docker_container.web["eu-1"]` ...). Terraform has no idea they are the same thing.

## Hint 2
Tell it with `moved` blocks - one per instance:
`moved { from = docker_container.web[0]  to = docker_container.web["eu-1"] }`.
Which index belonged to which site? Look at `var.sites` in the old commit (`git show HEAD~1:web/main.tf`).

## Hint 3
Six `moved` blocks (index order = the old list order), then `terraform plan`: six "has moved to"
lines and `0 to add, 0 to change, 0 to destroy`. Apply to record the move in state.
