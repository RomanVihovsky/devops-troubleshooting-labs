# "Too many open files"
**LNX-105** · P1 · Reporter: on-call

The `catalog-api` service (port 8081) crash-loops: `OSError: [Errno 24] Too many open files`.
A colleague already raised the limit in `/etc/security/limits.conf` to 65535 and even
rebooted. Still failing. `ulimit -n` in their shell says 65535.

**Test**: `catalog-api` is running, `curl localhost:8081/` returns 200, and the process
is allowed at least 4096 open files.
