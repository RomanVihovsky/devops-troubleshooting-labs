# orders lost its database after the migration
**INC-2511** · P1 · Reporter: team orders

We moved the orders database from the old box into the cluster last night: the new one is `pg-new` (namespace
`legacy`). The app connects to `db:5432`; `db` is a Service **without a selector** that we pointed at the old box
by hand years ago (`workspace/N10/db.yaml`). The old database was shut down this morning (it stays off), and
`orders` has been failing its readiness since then. Point `db` at the new database. The app's settings stay as
they are.

**Test**: `orders` has 2 Ready pods with a working database connection; `db` leads to `pg-new`'s pod; the app
still uses `db:5432`; the old database stays off (0 replicas).
