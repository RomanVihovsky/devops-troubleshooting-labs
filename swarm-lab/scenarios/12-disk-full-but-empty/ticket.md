# Disk full, but there is nothing on the disk
**SWARM-112** · Priority P1 · Reporter: on-call

`/health` on `web` returns **503** `cannot write heartbeat: [Errno 28] No space left on device`.
The data volume is mounted at `/data`. Inside the container:

```
$ df -h /data      -> 100% used
$ du -sh /data     -> 8.0K
```

Nothing to delete! Restarting the task fixes it for ~20 seconds, then it's back.

**Done when**
- `/health` returns 200 via every node, and still does 30 s later
- `/data` usage below 50%
