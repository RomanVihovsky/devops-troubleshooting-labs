# L13 · DRY multi-env with feature flags
**Learn** · root.hcl + env.hcl hierarchy, stable state keys, feature flags, exclude · ~30 min

`live/` grew by copy-paste: every unit repeats the whole backend and provider config. `dev/web`,
`prod/web` and `prod/audit` are deployed. `dev/audit` was copied too but must **not** run in dev
unless someone asks for it explicitly.

1. Move the shared config into `live/root.hcl`, and the per-environment values into
   `live/dev/env.hcl` / `live/prod/env.hcl` (`env`, `replicas`). Units keep only what is unique to them.
2. **Keep the state keys exactly as they are** - the refactor must not create or move anything.
   (Compare the hard-coded keys with what `path_relative_to_include()` would produce.)
3. In both `audit` units: a `feature "audit"` flag that defaults to **on in prod, off elsewhere**,
   and an `exclude` block that drops the unit from `run --all` when the flag is off.
4. `terragrunt run --all plan` in `live/` -> no changes, `dev/audit` excluded.
   `terragrunt run --all --feature audit=true -- plan` -> now dev/audit would be created.

**Test**: no unit file contains `remote_state` or `generate` any more; `run --all plan` in `live/` shows no
changes; its Run Report has `dev/audit` excluded and `prod/audit` run; with `--feature audit=true` dev/audit
is included; nothing was recreated (dev 1 / prod 3 replicas, same buckets).
