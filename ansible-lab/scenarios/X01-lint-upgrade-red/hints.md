## Hint 1
Run `sh ci/lint.sh` and read the rule ids: `fqcn`, `name[play]`, `name[casing]`, `yaml[truthy]`, `no-free-form`,
`risky-file-permissions`, `jinja[spacing]`, `no-changed-when`, `command-instead-of-module`, `literal-compare`, `var-naming[no-reserved]`...
`ansible-lint -L` explains each one.

## Hint 2
Most are mechanical: `ansible.builtin.` prefixes, `true` instead of `yes`, `mode:` on files, YAML arguments instead
of `key=value`, a play name, capitalized task names, `{{ port }}`. Compare booleans directly (`when: start_nginx`).
`port` is a reserved name (it is a play keyword - the SSH port): rename the variable, e.g. `app_port`.

## Hint 3
`systemctl reload nginx` on every run is what a **handler** is for: `notify: Reload nginx` on the config task and
an `ansible.builtin.service` handler with `state: reloaded`.
