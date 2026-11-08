## Hint 1
`--diff` prints the before/after of every template. 2.22 masks *known* secrets in diffs - is a value read from a
JSON file known to be secret?

## Hint 2
Two levers: turn the diff off for that task (`diff: false` - the task still reports `changed`), or tell Ansible
the value is secret when loading it (`| ansible.builtin.register_secret`).

## Hint 3
`diff: false` on *DB client config* is the safe minimum: other fields of that file (user, host) could be
sensitive too.
