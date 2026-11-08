# Solution - `order: sorted` replaced the canary; `max_fail_percentage: 50` tolerated one failure per batch

**Root cause**
1. `order: sorted` (OPS-2950) re-sorts the play's hosts **before** `serial` builds the batches: app1, app2, web1, web2.
   The canary batch became app1 (Debian - 5.0.0 works there), web2 went last.
2. `max_fail_percentage` must be **exceeded**: in the batch [app2, web1], one failure is exactly 50 %, so the
   rollout continued and also broke web2.

**Fix**
```yaml
  serial: [1, 2]
  max_fail_percentage: 0     # or any_errors_fatal: true
  # no order: - the inventory order is the rollout order (canary first)
```
5.0.0 now fails on web2 alone and stops; 5.0.1 passes the canary, fails on app1 in the next batch and stops there.

**Interview notes**
* Batch maths: `serial: [1, 2]` -> batches of 1, 2, then 2...; `max_fail_percentage` is evaluated **per batch** and
  must be exceeded (to stop at 2 of 4 failures, use 49, not 50). `0` = any failure.
* `order` applies before `serial`; `shuffle` makes canaries random. A canary is better made explicit: its own group
  and play (`hosts: canary`, then `hosts: shop:!canary`) - independent of sort orders.
* A failed host is out of the play: later batches don't retry it; handlers on failed hosts don't run
  (`force_handlers`).
