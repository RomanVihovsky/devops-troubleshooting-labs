# Solution - L13

Reference: `.lab/solve.sh`.
```
live/root.hcl              backend (key from path_relative_to_include) + provider + inputs from env.hcl
live/<env>/env.hcl         locals { env, replicas }
live/<env>/<unit>/terragrunt.hcl   include + source (+ feature/exclude for audit)
```

**Takeaways**
* DRY refactors of Terragrunt are state refactors in disguise: the backend `key` is the identity.
  `path_relative_to_include()` reproduces "<env>/<unit>" only if the layout matches - otherwise
  migrate state (`terragrunt run -- init -migrate-state`) or keep the old key explicitly.
* Hierarchy: `root.hcl` (org) -> `env.hcl`/`region.hcl` (read with `read_terragrunt_config` +
  `find_in_parent_folders`) -> unit. Use `include { expose = true }` to read included locals in a unit.
* `feature` flags (1.x) are typed toggles settable per run (`--feature`, `TG_FEATURE`); `exclude`
  removes units from the queue (`actions`, `exclude_dependencies`) and shows up in the Run Report.
  It does not stop a single-unit `terragrunt apply` - use a `before_hook` for hard bans.
* Related: `errors { retry ... ignore ... }` replaces `retryable_errors` (incident G11).
