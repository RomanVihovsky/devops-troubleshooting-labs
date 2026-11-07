# Solution - a drift detector must refresh

**Root cause**: `-refresh=false` makes Terraform compare the code with the **state**, not with reality.
A console change doesn't touch the state, so there is never a difference.

**Fix**: plain `terraform plan -detailed-exitcode` (or `-refresh-only -detailed-exitcode`, which reports
only out-of-band changes, not unapplied code).

**Interview notes**
* Exit codes: 0 none, 1 error, 2 changes. Under `set -e` capture them explicitly; never `|| true`.
* `-refresh=false` is for speed in huge stacks when you know nothing drifted - never for drift detection.
* Data sources inside `check` blocks make `-detailed-exitcode` return 2 with no real change (L07):
  evaluate the plan JSON if you use them.
* Route drift to the owning team with the plan attached; decide "revert" vs "codify" (incident D03).
