# PR dry-run always says "Stop the app for the upgrade" - reviewers stopped reading it
**OPS-305** · P2 · Reporter: release manager

`ci/pr-check.sh` (`--check --diff`) predicts an app restart on **every** PR, even README-only ones. The real
deploy then changes nothing. Reviewers learned to ignore the prediction - last week a real restart in business
hours slipped through.

The dry run must stay a dry run (nothing may change on app1), and it must tell the truth.

**Test**: check mode reports no changes on a converged node; check mode with `app_version=9.9.9` predicts
*Stop the app for the upgrade*; app1 is untouched by dry runs; no `ignore_errors`; the real deploy works.
