# Solution - L10

Reference: `.lab/solve.sh`.

**Takeaways**
* A task with `delegate_to` still runs once **per host in the play** - delegation changes *where*, not
  *how often*. Once per run: `run_once: true` (careful: once per **batch** with `serial` - incident E06) or,
  clearer, a separate play for the database.
* Rolling recipe: `serial` + `max_fail_percentage`/`any_errors_fatal` + drain -> change -> `flush_handlers`
  -> health gate -> enable. Each batch is complete before the next starts.
* Even a *good* release restarts processes: without draining, the load balancer still sends requests into the
  restart window.
* `serial: [1, "50%"]` = canary first, then bigger batches; `throttle:` limits concurrency for single tasks.
