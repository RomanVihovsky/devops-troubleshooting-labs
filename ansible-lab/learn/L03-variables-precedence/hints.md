## Hint 1
Inventory: add `prod: {hosts: {web1: }}` and `staging: {hosts: {web2: }}` under `all.children`. A host can
be in many groups. Group vars files are named after the group.

## Hint 2
Lowest to highest (the ones you use most): role defaults < inventory `group_vars/all` < `group_vars/<group>`
< `host_vars/<host>` < play vars < role vars < `set_fact` < extra vars (`-e`, always wins).

## Hint 3
`group_vars/prod.yml: motd_env: prod`, `group_vars/staging.yml: motd_env: staging`,
`group_vars/web.yml: motd_contact: web-oncall@acme.example`, `host_vars/web2.yml: motd_owner: Team Rocky`.
