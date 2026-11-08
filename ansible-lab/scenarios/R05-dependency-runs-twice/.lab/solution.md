# Solution - role dependencies with different parameters run twice

**Root cause**: `shop` and `api` both depend on `nginx_base`, each with its own `nginx_base_client_max_body_size`.
Ansible de-duplicates a dependency only when its parameters are identical; with different ones it runs it
twice. Each run writes 1m, then 50m - always "changed", two reloads, and the last writer (50m) wins for the
whole http block, shop included.

**Fix**: one owner per setting. `nginx_base` runs once (no parameters); the API's limit goes into the API's own
`server {}` block.

**Interview notes**
* De-duplication: same role + same params = run once; `allow_duplicates: true` in the role's meta forces repeats.
* Dependencies run before the depending role; `--list-tasks` shows the expansion.
* "Always changed" in an idempotence check usually means two writers for one file.
* Prefer explicit `roles:` / `include_role` in the play over deep `meta` dependency chains.
