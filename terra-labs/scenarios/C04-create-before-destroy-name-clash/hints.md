## Hint 1
With `create_before_destroy` the new container is created **while the old one still exists**. What
does Docker (or AWS, for ALB/IAM/... names) say about two objects with the same unique name?

## Hint 2
Make each generation's name unique - derived from what triggers the replacement, e.g.
`name = "tfl-api-${var.color}"`, or a `random_id` with `keepers = { color = var.color }`.
Consumers keep working because they use the alias, not the name.

## Hint 3
Change `name`, keep the lifecycle block, apply: plan shows `+/- create replacement and then destroy`.
