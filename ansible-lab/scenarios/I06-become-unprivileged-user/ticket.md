# app1: "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user"
**OPS-236** · P2 · Reporter: app team

The app config task (`become_user: acme`) fails on app1, the first node from the new minimal image. On the old
nodes it always worked. Pipelining is already on. The internet suggests
`allow_world_readable_tmpfiles = True` "and it works".

Make it work properly - nothing world-readable, no running the app's files as root.

**Test**: `/home/acme/app.ini` is created by and owned by `acme` (0600); site.yml converges; Ansible is not allowed
to fall back to world-readable temp files.
