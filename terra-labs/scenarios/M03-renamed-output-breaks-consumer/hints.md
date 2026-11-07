## Hint 1
Root module outputs are the API of a stack: other stacks read them through `terraform_remote_state`.
Renaming one is a breaking change for every reader. `terraform output` in `stacks/network` shows what exists now.

## Hint 2
Add the old name back next to the new one. Terraform 1.15 introduced `deprecated = "..."` for outputs and
variables - try it on this output and read the error carefully.

## Hint 3
`deprecated` only works on **module** outputs (it warns the calling module); a root output has no caller to
warn. So: `output "subnet_id" { value = aws_subnet.app.id  description = "DEPRECATED: use app_subnet_id ..." }`,
apply the network stack, plan payments.
