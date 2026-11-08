# L09 · Inventory at scale: constructed groups and patterns
**Learn** · inventory directories, `ansible.builtin.constructed`, keyed_groups, patterns, `--limit` · ~20 min

`inventory/01-cmdb.yml` is exported nightly from the CMDB: every host has `env`, `role` and `tier`, but
there are **no groups**. Nobody wants to maintain group lists by hand.

1. Add `inventory/02-constructed.yml` using the `ansible.builtin.constructed` plugin (`strict: true`):
   * `keyed_groups` -> `env_<env>` and `role_<role>`;
   * `groups` -> `critical` for every host with `tier == 'gold'`.
   `ansible.cfg` already points at the whole `inventory/` directory (files load in name order).
2. `ansible-inventory --graph` shows the new groups.
3. Write `patch.yml`: put the marker file `/etc/acme/patched` on **prod web servers only** - use a pattern
   that intersects two constructed groups, never a hostname. Try `--limit` and `--list-hosts` first.

**Test**: groups env_prod/env_staging/role_web/role_app/role_db/critical with the right members; only prod web
servers carry the marker; when a host moves to prod in the CMDB, patch.yml targets it automatically.
