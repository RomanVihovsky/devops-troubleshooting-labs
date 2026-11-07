## Hint 1
Beyond `rwx` and ownership, Linux has more ways to protect a file: ACLs (`getfacl`),
mount options (`findmnt -T /etc/app/app.conf`), and **file attributes**.
## Hint 2
`lsattr /etc/app/app.conf /var/log/app/audit.log`. What do the letters mean? (`man chattr`)
## Hint 3
`chattr -i` the config, edit it. Leave the audit log's `a` (append-only) attribute alone -
it may only grow.
