# L03 · Variables and precedence
**Learn** · group_vars, host_vars, role defaults, extra vars, ansible-inventory · ~20 min

The `motd` role writes `/etc/motd` from `motd_env`, `motd_owner` and `motd_contact` (see its `defaults/`).
**Do not edit the role** - configure it from the inventory side, like a real consumer of a shared role.

1. Groups: web1 is in `prod`, web2 in `staging` (both stay in `web`). Set `motd_env` per environment in
   `group_vars/prod.yml` / `group_vars/staging.yml`.
2. All web nodes: `motd_contact: web-oncall@acme.example` (`group_vars/web.yml`).
3. web2 belongs to another team: `motd_owner: Team Rocky` in `host_vars/web2.yml`.
4. `ansible-inventory --host web2` shows the merged result. Apply `site.yml`.
5. Experiment: `-e motd_env=hotfix` beats everything (don't commit that).

**Test**: web1's MOTD says env prod, owner Platform, contact web-oncall; web2's says env staging,
owner Team Rocky, contact web-oncall; the role is unchanged; site.yml converges.
