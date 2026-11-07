# Solution - unique names for create_before_destroy

**Root cause**: `create_before_destroy` creates the replacement first. Both generations would be called
`tfl-api` at the same moment, and container names are unique per Docker host.

**Fix**: derive the name from what changes: `name = "tfl-api-${var.color}"` (or a `random_id` with
`keepers`). Clients use the stable alias `api`, so the name is free to change.

**Interview notes**
* Same trap in AWS: IAM role/policy names, ALB target groups, launch templates, RDS identifiers,
  security group names. Hence the `name_prefix` arguments many resources offer.
* `create_before_destroy` propagates to dependencies (they become CBD too) - check what else changes.
* The failed apply already created nothing (the create failed first) - but in other cases a failed
  CBD can leave a "deposed" object in state; `terraform plan` shows it.
