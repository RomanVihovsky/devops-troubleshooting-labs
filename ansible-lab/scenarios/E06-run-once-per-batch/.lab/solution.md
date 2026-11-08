# Solution - run_once is per batch

**Root cause**: with `serial: 1` every app node is its own batch; `run_once: true` runs the task once **per
batch**, so the migration ran once per app node.

**Fix**: a separate play before the rollout that targets the database host - runs once per deployment,
before the first app node switches.

**Interview notes**
* Alternatives: `when: inventory_hostname == ansible_play_hosts_all[0]` (first host of the whole play),
  or a migration tool that is idempotent (Flyway/Alembic version tables) - ideally both.
* `run_once` + `delegate_to` sets facts/registers on all hosts of the batch, not the play.
* With `serial`, a play's `ansible_play_batch` is the current batch, `ansible_play_hosts_all` the whole play.
