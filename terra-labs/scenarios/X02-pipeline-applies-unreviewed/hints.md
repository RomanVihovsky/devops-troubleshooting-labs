## Hint 1
What does `apply` do in the script? Plan again from the current code - so the review of `plan.txt`
proves nothing about what gets applied.

## Hint 2
A **saved plan** is the artifact to review and to apply: `terraform plan -out=...` then
`terraform apply <planfile>`. Terraform refuses a saved plan if the state changed since (stale plan).

## Hint 3
plan: `terraform plan -out="$ART/tfplan"` and `terraform show -no-color "$ART/tfplan" > "$ART/plan.txt"`.
apply: `terraform apply -input=false "$ART/tfplan"` - and fail if that file does not exist.
