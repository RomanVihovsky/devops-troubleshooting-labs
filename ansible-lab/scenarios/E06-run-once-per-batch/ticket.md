# Release 3.2.0: the schema migration ran twice
**OPS-312** · P1 · Reporter: DBA

`/var/lib/acme/migrations.log` on db1 shows the 3.2.0 migration **twice** - the second run failed half-way on
a real database. The task has `run_once: true`. The app rollout must stay rolling (one node at a time).

**Test**: deploying a new version runs its migration exactly once, before any app node gets it; both app
nodes get the release; the app rollout is still serial.
