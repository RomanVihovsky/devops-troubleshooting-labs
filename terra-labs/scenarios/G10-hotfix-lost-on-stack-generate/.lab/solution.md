# Solution - change the stack, not the generated units

**Root cause**: `.terragrunt-stack/` is generated from `terragrunt.stack.hcl` (+ catalog units) by
`stack generate`, which `stack run` does first. The hand edit lived only in the generated copy; the next
generation overwrote it, and the nightly apply rolled prod back to 2.

**Fix**: `values = { replicas = 4 }` in `live/prod/terragrunt.stack.hcl`, commit, `stack run -- apply`.

**Interview notes**
* Generated directories (`.terragrunt-stack`, `.terragrunt-cache`, `.terraform`) are build artefacts:
  gitignored, never edited, safe to delete (`terragrunt stack clean`).
* During an incident a manual change is OK - the follow-up is the PR. Pause scheduled applies until
  it is merged.
* Terragrunt marks generated values files with a "Do not edit" header for a reason.
