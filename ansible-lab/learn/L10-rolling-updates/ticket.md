# L10 · Rolling updates: serial, drain, health gates, run_once
**Learn** · `serial`, `max_fail_percentage`, `delegate_to`, `run_once`, `flush_handlers`, `uri until` · ~35 min

`lb1` (haproxy, backend `app`) balances `app1` (Debian) and `app2` (Rocky). `deploy.yml` releases a new
version - and today every release causes a short outage, and the DB migration runs once **per app node**.
Rewrite `deploy.yml`:

1. **Migration once per deploy**: a first play (or task) that records the migration on `db1` exactly once
   (`run_once` + `delegate_to`, or a play for `db`) - idempotent: deploying the same version twice must not
   add a second line to `/var/lib/acme/migrations.log`.
2. **One node at a time** (`serial: 1`), stop on the first failure (`max_fail_percentage: 0`).
3. **Drain** the node in haproxy before touching it (`community.general.haproxy`, socket
   `/run/haproxy/admin.sock`, `delegate_to: lb1`), restart **inside** the batch (`meta: flush_handlers`),
   wait until `http://<node>:8080/health` answers 200, then **enable** it again.

**Test**: deploying 2.1.0 while the lab hammers `http://lb1/` loses zero requests; both nodes run 2.1.0 and are
back in rotation; the migration for 2.1.0 is logged exactly once; a repeated deploy changes nothing.
