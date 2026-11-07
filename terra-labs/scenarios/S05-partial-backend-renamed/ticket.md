# CI: terraform init fails with "Missing required argument"
**INFRA-152** · P2 · Reporter: on-call

The ledger pipeline (`ci/plan.sh prod`) is red since this morning's cleanup PR:
`terraform init` fails complaining about a missing required argument of the S3 backend. Locally it
"works on my machine" for the author. Nothing about the infrastructure changed.

Keep the cleanup (the recommended `.tfbackend` extension is fine).

**Test**: `ci/plan.sh prod` on a fresh checkout initialises the prod backend and exits 0 (no changes);
the prod backend file keeps its new name.
