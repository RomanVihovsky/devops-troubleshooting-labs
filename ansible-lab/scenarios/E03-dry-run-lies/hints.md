## Hint 1
Run `ansible-playbook site.yml --check -v`. What does the *Current version* task return in check mode?

## Hint 2
`command`/`shell` can't predict their effect, so in check mode they are **skipped** - and the registered result
says `rc: 0`, `stdout: ""`. `"" != app_version` is always true. Here the command only reads a file: it is safe
to run even in check mode.

## Hint 3
`check_mode: false` on *Current version* (it already has `changed_when: false`). Guards like
`when: not ansible_check_mode` would make the dry run blind instead of wrong.
