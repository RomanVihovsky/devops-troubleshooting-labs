# The deploy job has been waiting for 40 minutes
**INC-2472** · P2 · Reporter: release manager

The CI job for `storefront` 1.5 runs `kubectl -n storefront rollout status deploy/storefront` and has been
waiting for 40 minutes. The shop still works (on the old pods). Get storefront onto a working version, and make
sure the next broken release fails CI within **10 minutes** instead of hanging for an hour.

**Test**: storefront's rollout is complete with 3 Ready pods on a version that starts (1.4 is the last good
one); no ReplicaSet of storefront has pods that aren't Ready; `progressDeadlineSeconds` is at most 600.
