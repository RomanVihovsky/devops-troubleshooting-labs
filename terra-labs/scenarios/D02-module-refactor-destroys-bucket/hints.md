## Hint 1
`terraform plan` lists both sides: what it wants to destroy (old addresses) and to create
(`module.uploads.aws_s3_bucket.this` ...). Same bucket name - different address.

## Hint 2
`moved` blocks work across module boundaries: `from = aws_s3_bucket.uploads`,
`to = module.uploads.aws_s3_bucket.this`. Do it for all three resources.

## Hint 3
After three `moved` blocks the plan shows 3 moves and `0 to destroy`. Apply.
