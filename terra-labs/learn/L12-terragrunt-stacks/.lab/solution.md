# Solution - L12

Reference stack file: `.lab/solve.sh`.

**Takeaways**
* A stack file is the environment's bill of materials; the catalog holds reviewed, versioned unit
  templates (in real life: `git::...//units/app?ref=v1.4.0` sources).
* `values` -> `terragrunt.values.hcl` next to the generated unit -> `values.x` in the template.
  `autoinclude` (1.2) injects dependencies/inputs from the stack, so templates stay generic.
* `expansion { for_each | count }` (1.2) fans one block out; `enabled = ...` switches units off.
* `.terragrunt-stack/` is a build artefact: gitignore it, regenerate on demand (`stack run` does it),
  never hotfix inside it (incident G10). `stack clean` removes it.
* State keys come from the generated path (`dev/.terragrunt-stack/app-blue/...`) - renaming a unit
  path moves its state key; plan for it like any refactor.
