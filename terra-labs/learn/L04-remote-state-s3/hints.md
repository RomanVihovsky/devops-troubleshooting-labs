## Hint 1
Since AWS provider v4 the bucket's features are separate resources: `aws_s3_bucket_versioning`,
`aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block`.

## Hint 2
A partial backend: `backend "s3" {}` in code, the rest in an HCL file of key = value lines
(`bucket = "acme-tfstate"`, `key = ...`, `region = ...`, `use_lockfile = true`) passed with
`-backend-config=backend.hcl`. The same file then works for every developer and for CI.

## Hint 3
`terraform init -migrate-state -backend-config=backend.hcl` asks "Do you want to copy existing
state to the new backend?" -> yes. Verify with `aws s3 ls s3://acme-tfstate --recursive` and
`terraform state list`, then `rm terraform.tfstate terraform.tfstate.backup`.
