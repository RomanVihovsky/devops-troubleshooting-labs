## Hint 1
Older Terragrunt created missing state buckets implicitly. 1.x never does that silently. Which command
creates backend resources now? (`terragrunt backend --help`)

## Hint 2
`terragrunt backend bootstrap` creates the bucket with versioning, encryption, public access block (and
access logging, if configured). `aws s3 mb` creates a bare bucket - none of that.

## Hint 3
In `live/staging`: `terragrunt backend bootstrap --all` (or pass `--backend-bootstrap` to `run`), then
`terragrunt run --all -- apply`.
