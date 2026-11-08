# Solution - serial, fail fast, drain, health-gate

**Root cause**: `deploy.yml` changed all web nodes in parallel (default: every host in the batch) and
restarted them together through a handler. A broken build therefore broke every node at once, and
nothing stopped the run or protected the load balancer.

**Fix**
```yaml
serial: 1                     # one node per batch (or "30%", or [1, 5, "50%"] canary-style)
max_fail_percentage: 0        # any failure stops the whole play
pre_tasks:  community.general.haproxy state=disabled  delegate_to: lb1
tasks:      ... then meta: flush_handlers (restart inside the batch, not at the end)
            uri /health until 200  (health gate)
post_tasks: community.general.haproxy state=enabled wait=true
```
A failing node stays drained; the rest keep serving the old release.

**Interview notes**
* `serial` turns one play into batches; handlers run at the end of each batch; `max_fail_percentage` /
  `any_errors_fatal` decide when to stop.
* Health-gate inside the batch; otherwise the next batch starts while this one is still broken.
* Validate config before restarting (`validate:` on full configs, `nginx -t`) to fail *before* the outage.
* Even better: build immutable artefacts and canary them (serial `[1, "50%"]`).
