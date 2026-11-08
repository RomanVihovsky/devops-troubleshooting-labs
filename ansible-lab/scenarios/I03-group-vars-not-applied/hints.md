## Hint 1
`ansible-inventory --graph` and `ansible-inventory --host web1`: which groups does web1 belong to, and which
variables does it get?

## Hint 2
Group variable files are matched by the **exact** group name. And read the warning: dashes are "invalid
characters" in group names (they are not valid Python/Jinja identifiers).

## Hint 3
Use a valid name everywhere: group `web_servers` in the inventory and in `site.yml`, and
`group_vars/web_servers.yml`. Still 8080? Look at the play: `vars:` in a play beat group_vars - the reorganisation
put "defaults" there. Fallbacks belong in `group_vars/all.yml`.
