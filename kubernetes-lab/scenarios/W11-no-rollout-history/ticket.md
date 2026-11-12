# checkout is broken and we can't roll back
**INC-2502** · P1 · Reporter: on-call

`checkout`'s release went out ten minutes ago - `labapp:1.4` plus the new pricing integration (the `ERROR_RATE`
setting it introduced) - and now every `/items` request fails with 500. `kubectl -n pay rollout undo
deploy/checkout` says there is no history to roll back to. The previous release was `labapp:1.3` **without**
that setting (release notes). Get checkout back on the previous release, and make sure the next on-call **can**
use `rollout undo`.

**Test**: `checkout` has 3 Ready pods on `labapp:1.3`, and `/items` answers 200 in every pod; the Deployment keeps
rollout history again (`revisionHistoryLimit` >= 2).
