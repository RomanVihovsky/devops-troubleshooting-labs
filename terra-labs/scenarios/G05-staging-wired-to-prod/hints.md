## Hint 1
`terragrunt dag graph` in `live/` - which network does `staging/app` depend on?

## Hint 2
`dependency "network" { config_path = ... }` is a path relative to the unit. Copying a unit between
environments copies its paths too.

## Hint 3
`config_path = "../network"`, then `terragrunt run --all -- apply` in `live/staging` (the security group
moves VPC = replacement - fine for staging).
