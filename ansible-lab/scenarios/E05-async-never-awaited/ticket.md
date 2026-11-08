# Restore test failed: last night's dump stops after a few rows
**OPS-309** · P1 · Reporter: DBA

The monthly restore test failed: `backups/app1-acme.sql` (shipped by `backup.yml`) has the header and a few
INSERTs, but no `-- ACME dump complete` trailer. The backup job has been green for weeks. The dump itself takes
long - that's why it runs asynchronously (we hit SSH timeouts before).

**Test**: `backup.yml` ships a complete dump (trailer with this run's label) identical to the one on app1;
the dump still runs asynchronously.
