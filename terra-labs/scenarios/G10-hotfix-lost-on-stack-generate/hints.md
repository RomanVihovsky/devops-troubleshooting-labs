## Hint 1
Where does `.terragrunt-stack/web/terragrunt.values.hcl` come from? Look at its first line and at
`live/prod/terragrunt.stack.hcl`. What does `stack run` do before running anything?

## Hint 2
`.terragrunt-stack/` is generated output - regenerated from `terragrunt.stack.hcl` on every
`stack generate` / `stack run`. Editing it is like editing a compiled binary.

## Hint 3
Set `replicas = 4` in the `values` of `unit "web"` in `terragrunt.stack.hcl`, commit, then
`terragrunt stack run -- apply`.
