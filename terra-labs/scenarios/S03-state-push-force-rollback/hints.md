## Hint 1
`terraform state list` vs the code: which resources are missing? `terraform state pull | jq .serial`.
The state bucket keeps every version: `aws s3api list-object-versions --bucket acme-tfstate --prefix notifications/`.

## Hint 2
Download the versions and compare their resources (`jq '.resources | length'`), not just `serial` -
a forced push does not necessarily lower it:
`aws s3api get-object --bucket acme-tfstate --key notifications/terraform.tfstate --version-id <id> v.tfstate`.
The one just before the forced push is the good one.

## Hint 3
Check the good version's lineage equals the current one, then `terraform state push -force good.tfstate`
(same serial -> Terraform refuses without `-force`; this is the disaster recovery `-force` exists for).
Then `terraform plan` -> No changes.
