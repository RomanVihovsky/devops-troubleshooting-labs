# Solution - PID 1 shell swallows SIGTERM

**Root cause**: the stack overrides the entrypoint with `/app/start.sh`, which runs
`python /app/app.py` **without `exec`**. PID 1 is `/bin/sh`; Python is its child.
`docker stop` (and swarm on updates) sends SIGTERM to PID 1 only. The kernel does
not apply default signal actions to PID 1 of a namespace, and sh has no handler,
so nothing happens. After `stop_grace_period` (30 s) Docker sends SIGKILL - the app
never runs its graceful shutdown.

**Diagnose**
```
docker top <cid>                     # PID 1 = /bin/sh /app/start.sh, child = python
time docker stop <cid>               # ~30 s
docker logs <cid> | tail             # no "SIGTERM received"
cat /proc/<host pid of sh>/status | grep SigCgt   # no SIGTERM handler
```

**Fix** (any of)
- remove the `entrypoint` override (image CMD runs python as PID 1 - it handles SIGTERM)
- `exec python /app/app.py` in the script
- `init: true` (tini as PID 1 forwards signals) - fast stop, but here sh still
  dies first, so the app may be killed without its handler running

**Real-world notes**: also bites `CMD npm start` (npm doesn't forward signals),
`CMD java -jar app.jar` in shell form (`/bin/sh -c ...`), and zombie reaping
(PID 1 must `wait()` for orphans - use `init: true` / tini / dumb-init).
