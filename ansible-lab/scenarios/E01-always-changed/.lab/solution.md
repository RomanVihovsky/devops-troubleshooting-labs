# Solution - modules know state, commands don't

**Root cause**: `shell`/`command` always report `changed` - Ansible can't tell what a command did. Five of the
tasks were commands for things modules manage idempotently.

**Fix**: `user`, `file` (directory, link), `unarchive` (`remote_src`, `creates`), and `changed_when: false`
only on the read-only `uname -r`.

**Interview notes**
* Order of preference: a module > `command` with `creates`/`removes` > `command` with an honest
  `changed_when` (parse the output) > `changed_when: false` only for pure reads.
* `changed_when: false` on a state-changing command makes drift invisible - the idempotence gate goes green
  and lies.
* `command` + `creates` also gets check-mode support for free.
* ansible-lint: `no-changed-when`, `command-instead-of-module`, `command-instead-of-shell`, `risky-shell-pipe`.
