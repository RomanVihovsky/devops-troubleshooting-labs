# api won't stay at 2 replicas at night
**INC-2499** · P4 · Reporter: FinOps

To save money at night we scale `api` down: `kubectl -n api scale deploy/api --replicas=2`. Within a minute
it's back at 5. Nothing in our CI touches it. We still want autoscaling during the day (up to 10 under load) -
just let it go down to 2 when it's quiet.

**Test**: an HPA still scales `deploy/api` (maxReplicas >= 10) and allows 2 replicas; `api` runs 2 Ready pods
and stays at 2 for 60 s (no load).
