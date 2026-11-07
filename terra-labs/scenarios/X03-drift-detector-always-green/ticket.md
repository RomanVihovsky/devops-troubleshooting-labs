# Drift detector green for 6 weeks - prod limit was changed by hand
**PM-81** · P2 · Reporter: payments + postmortem review

Someone raised the payments transaction limit in the console (5000 -> 50000 EUR) six weeks ago.
The nightly `ci/drift.sh payments` was green every single night. Right now the console change is still
there.

Fix the detector so it actually detects drift. (Reverting the limit is the payments team's call -
leave it.)

**Test**: `ci/drift.sh payments` exits 2 while the hand-made change exists and 0 once reality matches the
code again (the lab tests both).
