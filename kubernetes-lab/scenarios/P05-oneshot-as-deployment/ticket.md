# orders-migrate is in CrashLoopBackOff although it succeeds
**INC-2457** · P3 · Reporter: team orders

Our schema migration `orders-migrate` (`workspace/P05/orders.yaml`) shows *CrashLoopBackOff* with dozens of
restarts. Its log ends with "migrate: ... done" and `kubectl describe` says *Exit Code: 0*. Every restart runs
the migration again. It should run **once per release** and stop.

**Test**: the migration runs as a Job that Completed (same command, `labapp migrate`); nothing runs it in a loop
any more (no Deployment or other always-restarting workload with that command); `orders` (the web app) has 2
Ready pods.
