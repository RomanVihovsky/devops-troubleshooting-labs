## Hint 1
Run `ci/drift.sh payments; echo $?`. Then run the same plan without the "speed-up" flag. What does
Terraform compare against when it doesn't refresh?

## Hint 2
`-refresh=false` means "assume the state is reality": Terraform never asks AWS, so changes made outside
Terraform are invisible. Drift detection *is* the refresh.

## Hint 3
Drop `-refresh=false`. Optional: `-refresh-only -detailed-exitcode` reports drift without mixing in
pending code changes.
