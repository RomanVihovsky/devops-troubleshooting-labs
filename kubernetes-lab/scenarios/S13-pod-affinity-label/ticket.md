# session-api never schedules
**INC-2505** · P3 · Reporter: team sessions

`session-api` must run on the same node as our Redis cache (`redis-cache`, latency) - that's what its pod affinity
is for (`workspace/S13/sessions.yaml`). Its pods stay *Pending*: *didn't match pod affinity rules*. The cache runs
fine.

**Test**: `session-api` has 2 Running pods, each on the node where the `redis-cache` pod runs; the co-location is
still a **required** pod affinity.
