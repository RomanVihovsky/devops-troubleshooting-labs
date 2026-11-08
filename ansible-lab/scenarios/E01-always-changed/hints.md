## Hint 1
`command` and `shell` can't know whether they changed anything, so they always report `changed`. Which of these
tasks have a real module that knows the state? `ansible-lint -t command-instead-of-module site.yml` lists them.

## Hint 2
User -> `ansible.builtin.user`; directory and symlink -> `ansible.builtin.file`; tarball -> `ansible.builtin.unarchive`
(`remote_src: true`, `creates:`). A command that only *reads* (`uname -r`) never changes anything:
`changed_when: false` is right **only** there.

## Hint 3
`changed_when: false` on `ln -sf` or `useradd` would hide drift - the verify deletes the symlink and the user
and expects the run to say `changed`.
