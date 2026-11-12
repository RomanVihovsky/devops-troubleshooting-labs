# worker has 0 pods, no errors on the pods (there are none)
**INC-2526** · P3 · Reporter: team B

`worker` (namespace `team-b`, `workspace/R05/worker.yaml`) was deployed an hour ago: the Deployment exists, 0/2
ready, and there are no pods to look at. The namespace has the platform team's standard limits - those stay.

**Test**: `worker` has 2 Ready pods; the namespace's LimitRange is unchanged.
