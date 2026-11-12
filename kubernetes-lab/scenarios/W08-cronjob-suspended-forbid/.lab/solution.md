# W08 - a CronJob that is both suspended and blocked

**Root cause**: an earlier run hung (`sleep 3600`) and stayed **active**. With `concurrencyPolicy: Forbid` the
controller skips every schedule while a run is active. The template was then fixed, but the CronJob was also
`suspend: true`. Fixing the template doesn't touch the running Job.

**Diagnosis**
```
kubectl -n cron get cronjob export -o wide        # SUSPEND True, ACTIVE 1
kubectl -n cron get jobs                           # an old Job, 0/1, age: long
kubectl -n cron describe cronjob export | tail     # events: "Not starting job because prior execution is still running"
```

**Fix**: delete the hung Job, set `suspend: false`, wait for the next schedule.

**Interview notes**
- `concurrencyPolicy`: `Allow` (overlap), `Forbid` (skip while one runs: a hang blocks everything), `Replace`
  (kill the old run). Add `activeDeadlineSeconds` to the job template so a hang ends by itself.
- `startingDeadlineSeconds`: if the controller misses a schedule by more than this (controller down, or
  >100 missed schedules), that run is skipped. "Cannot determine if job needs to be started... too many
  missed start times" is the classic.
- Time zones: `spec.timeZone: Europe/Berlin` (stable since 1.27); without it, the controller's (UTC) time.
