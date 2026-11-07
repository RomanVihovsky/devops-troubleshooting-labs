# Disk full, but there is nothing on it
**LNX-107** · P1 · Reporter: on-call

`/data` on `srv` is 100% full; uploads fail with "No space left on device". Someone
already "cleaned up" a huge file there this morning, but `df -h /data` still says 100%,
while `du -sh /data` reports only a few KB.

`queue-worker` holds two hours of un-flushed messages **in memory**: do **not** restart
or kill it.

**Test**: `/data` below 50% used, a 10 MB test file can be written there, and
`queue-worker` still runs with the **same PID**.
