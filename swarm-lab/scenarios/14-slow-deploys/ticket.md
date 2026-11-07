# Every deploy takes minutes
**SWARM-114** · Priority P3 · Reporter: dev team

A rolling update of `web` (3 replicas, one at a time) takes ~2 minutes. Each old
task sits in `Running`/`Shutdown` for exactly ~30 seconds before it goes away.
The developers insist: "the app handles SIGTERM and exits in under a second -
it even logs `SIGTERM received, shutting down gracefully`." We never see that line.

**Done when**
- stopping a `web` container takes < 5 s **and** the app logs its graceful shutdown
- `app_web` is 3/3 and answers via every node
