# demo keeps flipping OutOfSync, pods come and go
**INC-2318** · P3 · Reporter: platform team

For the sale we gave `demo` an autoscaler yesterday (`kubectl -n demo get hpa`: at least 3 replicas, up to 6).
Since then Argo CD shows demo *OutOfSync* and *Synced* in turns, its history fills with auto-syncs, and a
third pod is created and killed every minute. Keep the autoscaling (at least 3 replicas) and stop the fight -
the fix goes through Git.

**Test**: demo stays Synced with no new sync operation for 2 minutes; exactly one HPA scales `deploy/demo`
(minReplicas >= 3) and the Deployment's replicas follow it; Git no longer pins the replica count (or Argo CD
is told to ignore it, *and* to respect that when it syncs).
