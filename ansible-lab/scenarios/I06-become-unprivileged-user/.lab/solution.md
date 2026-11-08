# Solution - install acl

**Root cause**: with `become_user` set to an unprivileged account, Ansible uploads module files as the
connection user and must let the target user read them. It tries `setfacl` first; the minimal image has no
`acl` package, the other fallbacks fail, and Ansible refuses to make the files world-readable.

**Fix**: install `acl` as root before tasks that become an unprivileged user.

**Interview notes**
* Order of attempts: `setfacl` -> `chown` (only if connection user is root) -> `chmod +a` (macOS) -> shared
  `common_remote_group` -> world-readable (only if `allow_world_readable_tmpfiles`). The last one leaks secrets
  in module args to every local user.
* Pipelining avoids temp files for *module* execution, not for file transfers (`copy`, `template`).
* Alternatives: `become_user` root + `owner:` on the file - simpler when the user doesn't need to run anything.
