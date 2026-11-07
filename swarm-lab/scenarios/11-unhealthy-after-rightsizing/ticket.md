# web never becomes healthy after "right-sizing"
**SWARM-111** · Priority P2 · Reporter: FinOps / on-call

FinOps merged PR #482 "right-size web: it idles at 1% CPU". Since then `web`
never becomes healthy: tasks sit in `Starting`, then get killed as unhealthy and
replaced. Memory use is tiny, logs show nothing wrong (just slow?).
`/health` runs a built-in **self-test** that compliance requires - it must stay.

**Done when**
- `app_web` is 2/2 and stays up (no task replaced for 15 s)
- `SELFTEST_ROUNDS` unchanged, healthcheck still configured
- `/health` answers in < 1 s via every node
