## Hint 1
Diff the two stacks' `versions.tf`. What does each pipeline do with resources that are in the state
but not in its own code?

## Hint 2
Recs needs its own state key. But careful how you switch: `terraform init` will offer to copy the
existing state to the new key (`-migrate-state`). What would recs' next plan do with search's
resources if you accept?

## Hint 3
Change the key in `stacks/recs`, then `terraform init -reconfigure` (start empty there - recs owns
nothing yet) and `terraform apply`. Search stays where it is. Check both plans.
