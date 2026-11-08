# Solution - merge dictionaries explicitly

**Root cause**: `group_vars/prod.yml` redefined `nginx_settings` with one key. Higher-precedence definitions
**replace** the whole dict, so prod lost `gzip` and `keepalive_timeout`.

**Fix**: shared `nginx_settings_defaults` + per-group `nginx_settings_overrides` + `combine()` (use
`combine(..., recursive=true)` for nested dicts, `list_merge=` for lists).

**Interview notes**
* `hash_behaviour = merge` changes this for **everything** (all dicts, all levels) - hard to reason about; avoid.
* Layered config pattern: `*_defaults` / `*_overrides` / computed var, or `community.general.merge_variables`.
* Diff your rendered configs (`--check --diff`) on every inventory change - this would have been obvious.
