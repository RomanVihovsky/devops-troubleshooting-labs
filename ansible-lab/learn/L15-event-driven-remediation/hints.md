## Hint 1
A rule is `name` + `condition` + `action`. Conditions are expressions on the event:
`event.payload.check == "nginx" and event.payload.status == "down"`. The action:
`run_playbook: {name: remediate/nginx.yml}` (paths are relative to the project directory).

## Hint 2
`./lab eda logs` shows the rulebook loading, every POST (`aiohttp.access`), the debug rule's printed events and
the playbook output. A YAML or schema error stops the activation - the log says why. In `./lab sh` you can
also run `ansible-rulebook --rulebook rulebooks/nginx.yml -i inventory/hosts.yml --print-events -v` yourself
(on another port).

## Hint 3
In `remediate/nginx.yml`: `hosts: "{{ ansible_eda.event.payload.host }}"` - extra vars are templated in the play's
`hosts:`; the ruleset's `hosts: web` becomes the `--limit`, so only web hosts can ever match.
