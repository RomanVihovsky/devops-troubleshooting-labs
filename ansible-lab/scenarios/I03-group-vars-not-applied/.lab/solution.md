# Solution - group name and group_vars file must match (and be valid)

**Root cause**: the reorganisation renamed the group `webservers` -> `web-servers` but left
`group_vars/webservers.yml`. The vars file now belongs to a group that does not exist; the play falls back to
its own defaults (8080, unknown). The run warns: `Invalid characters were found in group names but not replaced`.

**Fix**: one valid name everywhere (`web_servers`): inventory, plays, `group_vars/web_servers.yml` - and move the
"defaults" the reorganisation put into the play's `vars:` (which beat group_vars) to `group_vars/all.yml`.

**Interview notes**
* `ansible-inventory --graph --vars` is the fastest way to see what a host really gets.
* Group names: letters, digits, underscores (Python identifiers). `TRANSFORM_INVALID_GROUP_CHARS` can rewrite
  them, but then file names and `hosts:` patterns must follow the transformed name too.
* A variable in play `vars` beats group_vars - defaults in plays hide missing inventory data. Prefer role defaults.
