# web dies with exit code 137
**SWARM-110** · Priority P1 · Reporter: on-call

Since release 1.0 enabled the in-memory cache, `web` never stays up. Tasks die a
few seconds after start: `task: non-zero exit (137)`. There is **no healthcheck**
on this service. The last log line is always `warming up in-memory cache (192 MiB)...`.
"Works on my laptop" (dev runs it without limits).

The 192 MiB cache size is a **product requirement** - it must stay.

**Done when**
- `app_web` is 2/2 and stays up (no task replaced for 15 s)
- `CACHE_WARMUP_MB` is still 192
- http://172.30.0.{11,21,22}:8080 answer
