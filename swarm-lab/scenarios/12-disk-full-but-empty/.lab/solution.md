# Solution - deleted-but-open file eats the disk

**Root cause**: `LOG_LEVEL: debug` makes the app write ~2.5 MB/s to `/data/app.log`.
Its "housekeeping" rotates the log by **deleting** the file once it exceeds 16 MB,
but the app keeps the file descriptor open and keeps writing. The inode has no
name any more (`du` can't see it) but its blocks stay allocated (`df` can) until
the last descriptor closes. The 48 MB volume fills up; the heartbeat write fails.
A restart closes the descriptor (space comes back) - and the cycle restarts.

**Diagnose** (on the node running the task)
```
docker exec <cid> sh -c 'df -h /data; du -sh /data'
docker exec <cid> ls -l /proc/1/fd | grep deleted      # 3 -> /data/app.log (deleted)
lsof -p $(docker inspect -f '{{.State.Pid}}' <cid>) | grep deleted   # from the node
docker service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' app_web
```

**Mitigate now**: `docker exec <cid> sh -c ': > /proc/1/fd/3'` (truncate via the fd).
**Fix**: `LOG_LEVEL: info` and redeploy. (Proper rotation = `copytruncate`, or
signal the app to reopen its log, or log to stdout and let Docker rotate.)

**Real-world notes**: the classic version is `rm` on a huge log while nginx/java
still has it open; `df` stays at 100% until the process restarts.
`lsof +L1` lists open files with link count 0.
