## Hint 1
Git sources: `source = "git::https://git.acme.example/platform/tf-module-bucket.git?ref=v1.1.0"`.
`ref` can be a tag, branch or commit - pin a tag (or a commit), never a branch (incident M01).
After changing a source, `terraform init` (or `init -upgrade`) fetches it into `.terraform/modules`.

## Hint 2
`moved { from = aws_s3_bucket.media  to = module.media.aws_s3_bucket.this }` - and the same for the
versioning resource. The resource names inside the module are in its `main.tf`.

## Hint 3
`output "bucket_arn" { value = module.media.arn }`. The plan should read
`Plan: 1 to add, 0 to change, 0 to destroy` plus two "has moved to" notes.
